#target photoshop
/* Select Subject > Reveal Selection layer mask, once per selected image layer.
   Select layers in the Layers panel, then run File > Scripts >
   Mask_Subjects_Selected_Layers. Photoshop 2026 / ExtendScript.
   Pixels and Smart Objects stay intact. Existing masks are skipped.
*/
(function () {
    if (!app.documents.length) { alert("Open a document and select the image layers first."); return; }
    var doc = app.activeDocument;
    var s = stringIDToTypeID;
    var c = charIDToTypeID;
    var oldDialogs = app.displayDialogs;
    var originalActiveID = doc.activeLayer.id;
    var ids = [];
    var completed = 0;
    var notes = [];
    var cancelled = false;
    var replacementIDs = {};

    function selectedIDs() {
        var ref = new ActionReference();
        ref.putProperty(s("property"), s("targetLayersIDs"));
        ref.putEnumerated(s("document"), s("ordinal"), s("targetEnum"));
        var descriptor = executeActionGet(ref);
        if (!descriptor.hasKey(s("targetLayersIDs"))) {
            throw new Error("Photoshop did not provide the selected layer IDs. Select your layers again.");
        }
        var list = descriptor.getList(s("targetLayersIDs"));
        var result = [];
        for (var i = 0; i < list.count; i++) { result.push(list.getReference(i).getIdentifier()); }
        return result;
    }
    function selectLayer(id, add) {
        var desc = new ActionDescriptor();
        var ref = new ActionReference();
        ref.putIdentifier(s("layer"), id);
        desc.putReference(s("null"), ref);
        if (add) { desc.putEnumerated(s("selectionModifier"), s("selectionModifierType"), s("addToSelection")); }
        desc.putBoolean(s("makeVisible"), false);
        executeAction(s("select"), desc, DialogModes.NO);
    }
    function hasMask(id) {
        var ref = new ActionReference();
        ref.putProperty(s("property"), s("hasUserMask"));
        ref.putIdentifier(s("layer"), id);
        var desc = executeActionGet(ref);
        return desc.hasKey(s("hasUserMask")) && desc.getBoolean(s("hasUserMask"));
    }
    function makeMask() {
        var desc = new ActionDescriptor();
        var at = new ActionReference();
        desc.putClass(c("Nw  "), c("Chnl"));
        at.putEnumerated(c("Chnl"), c("Chnl"), c("Msk "));
        desc.putReference(c("At  "), at);
        desc.putEnumerated(c("Usng"), c("UsrM"), c("RvlS"));
        executeAction(c("Mk  "), desc, DialogModes.NO);
    }
    function deselect() { try { doc.selection.deselect(); } catch (ignored) {} }
    function currentID(id) { return replacementIDs[id] || id; }
    function restoreLayerSelection() {
        var order = [];
        var i;
        for (i = 0; i < ids.length; i++) { if (ids[i] !== originalActiveID) { order.push(currentID(ids[i])); } }
        order.push(currentID(originalActiveID));
        var first = true;
        for (i = 0; i < order.length; i++) {
            try { selectLayer(order[i], !first); first = false; } catch (ignored) {}
        }
    }
    function revealForProcessing(layer) {
        var hidden = [];
        var cursor = layer;
        while (cursor && cursor.typename !== "Document") {
            if (!cursor.visible) { hidden.push(cursor); }
            cursor = cursor.parent;
        }
        // Parents first, then the layer. Record before changing anything.
        try {
            for (var i = hidden.length - 1; i >= 0; i--) { hidden[i].visible = true; }
        } catch (err) {
            restoreVisibility(hidden); throw err;
        }
        return hidden;
    }
    function restoreVisibility(hidden) {
        for (var i = 0; i < hidden.length; i++) { try { hidden[i].visible = false; } catch (ignored) {} }
    }
    function processLayers() {
        for (var i = 0; i < ids.length; i++) {
            var name = "Layer ID " + ids[i];
            var hidden = [];
            var beforeState = null;
            try {
                selectLayer(ids[i], false);
                var layer = doc.activeLayer;
                name = layer.name;
                if (layer.typename !== "ArtLayer" || (layer.kind !== LayerKind.NORMAL && layer.kind !== LayerKind.SMARTOBJECT)) {
                    notes.push(name + ": skipped (select an image layer or Smart Object, not a group, text, or adjustment layer).");
                    continue;
                }
                if (hasMask(ids[i])) { notes.push(name + ": skipped (already has a layer mask)."); continue; }
                if (!layer.isBackgroundLayer && layer.allLocked) { notes.push(name + ": skipped (layer is locked)."); continue; }
                beforeState = doc.activeHistoryState;
                hidden = revealForProcessing(layer);
                doc.activeChannels = doc.componentChannels;
                deselect();
                var subject = new ActionDescriptor();
                subject.putBoolean(s("sampleAllLayers"), false);
                executeAction(s("autoCutout"), subject, DialogModes.NO);
                // An empty selection must never create a reveal-all mask.
                try { var bounds = doc.selection.bounds; }
                catch (noSubject) { throw new Error("No subject was detected."); }
                if (layer.isBackgroundLayer) { layer.isBackgroundLayer = false; }
                makeMask();
                replacementIDs[ids[i]] = doc.activeLayer.id;
                completed++;
                deselect();
            } catch (err) {
                if (beforeState) {
                    try { doc.activeHistoryState = beforeState; }
                    catch (undoError) { notes.push(name + ": could not roll back the unsuccessful operation; inspect this layer."); }
                }
                if (err.number === 8007 || /user cancel|cancelled|canceled/i.test(String(err.message))) { cancelled = true; break; }
                notes.push(name + ": " + (err.message || err.toString()));
            } finally {
                restoreVisibility(hidden);
            }
        }
    }

    try { ids = selectedIDs(); }
    catch (err) { alert("Could not read selected layers: " + err.message); return; }
    if (!ids.length) { alert("Select one or more image layers in the Layers panel first."); return; }

    // suspendHistory evaluates a string; expose a short-lived callback explicitly.
    var key = "__adobeJSXMaskSubjectsSelectedLayers";
    var priorCallback = $.global[key];
    $.global[key] = processLayers;
    try {
        app.displayDialogs = DialogModes.NO;
        doc.suspendHistory("Select Subject + Mask Selected Layers", "$.global.__adobeJSXMaskSubjectsSelectedLayers()");
    } catch (err) {
        notes.push("Script stopped: " + (err.message || err.toString()));
    } finally {
        try {
            deselect();
            doc.activeChannels = doc.componentChannels;
            restoreLayerSelection();
        } catch (ignored) {}
        app.displayDialogs = oldDialogs;
        if (typeof priorCallback === "undefined") { delete $.global[key]; }
        else { $.global[key] = priorCallback; }
    }
    var summary = "Added subject masks to " + completed + " of " + ids.length + " selected layers.";
    if (cancelled) { summary += "\nCancelled. Masks already completed are kept."; }
    if (notes.length) {
        var limit = Math.min(notes.length, 12);
        summary += "\n\n" + notes.slice(0, limit).join("\n");
        if (notes.length > limit) { summary += "\n...and " + (notes.length - limit) + " more."; }
    }
    alert(summary);
}());
