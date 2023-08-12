var ot = require ("./opentype.js");

(async () => {

  var font = await ot.load (process.argv[2]);

  var gg = Object.values (font.glyphs.glyphs);
  gg.forEach (_ => _.getMetrics ());
  var data = {
    cmap: font.tables.cmap.subtables.map (_ => ({glyphIndexMap:_.glyphIndexMap,encodingId:_.encodingID,platformID:_.platformID})),
    glyphs: gg.filter (_ => _.isComposite).map (_ => [_.index, _.components]),
  };
  
  process.stdout.write (JSON.stringify (data));

}) ();

/* License: Public Domain. */
