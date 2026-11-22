#target aftereffects
// Creates a new composition. Does not save, render, or alter existing comps.
(function () {
    if (!app.project) { app.newProject(); }
    app.beginUndoGroup("Create Sample Animated Title");
    try {
        var comp = app.project.items.addComp("JSX Sample - Animated Title", 1080, 1920, 1, 5, 30);
        comp.layers.addSolid([0.94, 0.91, 0.85], "Cream background", 1080, 1920, 1, 5);
        var layer = comp.layers.addText("HELLO\rADOBE JSX");
        var source = layer.property("ADBE Text Properties").property("ADBE Text Document");
        var text = source.value;
        text.fontSize = 100; text.applyFill = true; text.fillColor = [0.08, 0.13, 0.16];
        text.justification = ParagraphJustification.CENTER_JUSTIFY; source.setValue(text);
        var rect = layer.sourceRectAtTime(0, false);
        var transform = layer.property("ADBE Transform Group");
        transform.property("ADBE Anchor Point").setValue([rect.left + rect.width / 2, rect.top + rect.height / 2]);
        transform.property("ADBE Position").setValuesAtTimes([0, 0.8], [[540, 1050], [540, 960]]);
        transform.property("ADBE Opacity").setValuesAtTimes([0, 0.8, 4.2, 5], [0, 100, 100, 0]);
        comp.openInViewer();
    } catch (err) { alert("Could not create the sample: " + err.toString()); }
    finally { app.endUndoGroup(); }
}());
