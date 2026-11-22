#target illustrator
// Creates a new editable document. Does not save or alter existing documents.
(function () {
    var colors = [[27, 42, 50], [50, 93, 101], [125, 156, 147], [219, 207, 181], [246, 240, 228]];
    var doc = app.documents.add(DocumentColorSpace.RGB, 700, 260);
    for (var i = 0; i < colors.length; i++) {
        var swatch = doc.pathItems.rectangle(205, 40 + i * 128, 108, 145);
        var color = new RGBColor();
        color.red = colors[i][0]; color.green = colors[i][1]; color.blue = colors[i][2];
        swatch.fillColor = color; swatch.stroked = false;
        swatch.name = "Palette color " + (i + 1);
    }
    alert("Created five editable color swatches in a new document.");
}());
