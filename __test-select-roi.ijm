coordUnits = newArray ("deg", "rad", "arcmin", "arcsec", "pix");
geometry = newArray ("box", "centerbox", "rotbox", "poly", "circle", "annulus", "ellipse"); 

//path = File.openDialog("Select a Region File");
//fx = File.openAsString(path);
fx = File.openAsString("/home/david/Research/Tests/madcuba-alma-rois/rotated-rectangle-carta.crtf");

rows = split(fx,"\n\r");      //Separate file into rows
for(i = 0; i< rows.length; i++){         //Iterate through csv list
    if (startsWith(rows[i] ,"#") == 0) {        //skip first line
      if (indexOf(rows[i], "coord=") != -1) { 
          data = split(substring( rows[i] ,indexOf(rows[i], "coord="), indexOf(rows[i], "coord=")+30), "=,");
               // search where the coord system is and store it at data[1]. +30 is arbitrary, to give enough characters for every possibility
          if (call("FITS_CARD.getStr","RADESYS") != data[1]) print ("WARNING:  Coordinate system in ALMA Roi different that that in cube");
      }
      data = split(rows[i],"][,");      // store different important data in an array. Some of these strings are preceded or followed by a black space.
    }                                   // that is why later the 'if conditions' are not comparing data[0] () with strings, but locating the
}                                       // position of the polygon string in the array data[0]. i.e data[0] is "rotbox " and not "rotbox"

print("New run");
for ( j = 0; j<data.length; j++ ){
    print("data[" + j +"]: " + data[j] +".");
}

// TESTS indexOf. Use geometry 2 because the file is a rotated rectangle.
print(indexOf("rotbox ", "rotbox"));    //only correct one
print(indexOf("rotbox", "rotbox "));
print(indexOf("rotbox", " rotbox"));