coordUnits = newArray ("deg", "rad", "arcmin", "arcsec", "pix");
geometry = newArray ("box", "centerbox", "rotbox", "poly", "circle", "annulus", "ellipse"); 

//path = File.openDialog("Select a Region File");
//fx = File.openAsString(path);
fx = File.openAsString("/home/david/Research/Tests/madcuba-alma-rois/rectangle-carta.crtf");

rows = split(fx,"\n\r");      //Separate file into rows
for (i=0; i<rows.length; i++) {         //Iterate through csv list
  if (startsWith(rows[i],"#") == 0) {        //skip first line
    if (indexOf(rows[i], "coord=") != -1) { 
      data = split(substring(rows[i], indexOf(rows[i], "coord="), indexOf(rows[i], "coord=")+30), "=,");
        // search where the coord system is and store it at data[1]. +30 is arbitrary, to give enough characters for every possibility
      if (call("FITS_CARD.getStr","RADESYS") != data[1]) print("WARNING:  Coordinate system in ALMA Roi different that that in cube");
    }
    data = split(rows[i], "][,");      // store different important data in an array. Some of these strings are preceded or followed by a black space.
  }                                   // that is why later the 'if conditions' are not comparing data[0] () with strings, but locating the
}                                     // position of the polygon string in the array data[0]. i.e data[0] is "rotbox " and not "rotbox"

print("New run");
for (j=0; j<6; j++) {
  print("data[" + j + "]: '" + data[j] + "'");
}

function parseALMACoord (ra, dec) {
  // Convert coordinates to pixel 
  coordUnits = newArray ("deg", "rad", "pix");
  unitsval= 10;
  output = newArray(2);
  for(j=0; j<coordUnits.length; j++) { if (indexOf(ra, coordUnits[j])!=-1)  unitsval=j;}  // read coordinate unit
  if (unitsval == 10) {   // caso de coordenadas sesagesimales.   
    // TEMPORARY. Quick abortion of function for the polygon drawing. May be better put in another simpler and more coherent way.
    // Temporary in here because unitsval gets assigned 10 and the last iteration in the 'while' loop enters here. It has to yoild -1.   
    if (indexOf(ra, "corr") == 0 || indexOf(ra, "corr") == 1) {
      output[0] = -1;
      output[1] = -1;
    } else {
      // right ascension
      par = split(ra,"hdms:"); 
      if (par.length==1 && indexOf(ra, ".")<=5) {
        par = split(ra,"."); 
        if( par.length >3) par[2]=par[2]+"."+par[3]; 
      } 
      rafin = (parseFloat (par[0])+parseFloat (par[1])/60.0+parseFloat (par[2])/3600.0)*15.0;
      // declination
      par = split(dec,"hdms:"); 
      if (par.length ==1 && indexOf(dec, ".") <=5 ) {
        par = split(dec,"."); 
        if( par.length >3) par[2]=par[2]+"."+par[3]; 
      } 
      if (indexOf(dec, "-")  !=-1) decfin = parseFloat (par[0])-parseFloat (par[1])/60.0-parseFloat (par[2])/3600.0;
      else decfin = parseFloat (par[0])+parseFloat (par[1])/60.0+parseFloat (par[2])/3600.0;

      output[0] = call("CONVERT_PIXELS_COORDINATES.coord2FitsX",rafin, decfin,""); 
      output[1] = call("CONVERT_PIXELS_COORDINATES.coord2FitsY",rafin, decfin,""); 
    }
  } else { 
    rafin = substring(ra, 0, indexOf(ra, coordUnits[unitsval]));   // there was a parseFloat here but it deleted many decimals and got incorrect results
    decfin = substring(dec, 0, indexOf(dec, coordUnits[unitsval])); // here too
    if ( unitsval == 0 || unitsval == 1) {
      if( unitsval == 1 ) {
        rafin =  rafin*180.0/PI;
        decfin = decfin*180.0/PI;
      }
      output[0] = call("CONVERT_PIXELS_COORDINATES.coord2FitsX",rafin, decfin,""); 
      output[1] = call("CONVERT_PIXELS_COORDINATES.coord2FitsY",rafin, decfin,""); 

    } else if ( unitsval == 2) {
      output[0] = rafin;
      output[1] = decfin;
    }      
  }
  return output; 
}


function parseALMAxy (valx,valy) {
  // Convert an arc in the sky to pixels
  coordUnits = newArray ("deg", "rad", "arcmin", "arcsec", "pix");  
  unitsval=-1;
  coord = newArray(2);
  coord[0] =-1;

  for(j = 0; j< coordUnits.length; j++) { if (indexOf(valx, coordUnits[j]) !=-1)  unitsval=j;}
  if( unitsval == -1) return coord; // case of request without unit to use with polygon

  value = parseFloat (substring(valx, 0, indexOf(valx, coordUnits[unitsval])));  
  if ( unitsval == 0 ) coord[0] = value/parseFloat(call("FITS_CARD.getDbl","CDELT1"));
  else if ( unitsval == 1 ) coord[0] = (value*180.0/PI)/parseFloat(call("FITS_CARD.getDbl","CDELT1"));
  else if ( unitsval == 2 ) coord[0] = (value/60.0)/parseFloat(call("FITS_CARD.getDbl","CDELT1"));
  else if ( unitsval == 3 ) coord[0] = (value/3600.0)/parseFloat(call("FITS_CARD.getDbl","CDELT1"));
  else if ( unitsval == 4 ) coord[0] = value;

  for(j = 0; j< coordUnits.length; j++) { if (indexOf(valy, coordUnits[j]) !=-1)  unitsval=j;}
  value = parseFloat (substring(valy, 0, indexOf(valy, coordUnits[unitsval])));  
  if ( unitsval == 0 ) coord[1] = value/parseFloat(call("FITS_CARD.getDbl","CDELT2"));
  else if ( unitsval == 1 ) coord[1] = (value*180.0/PI)/parseFloat(call("FITS_CARD.getDbl","CDELT2"));
  else if ( unitsval == 2 ) coord[1] = (value/60.0)/parseFloat(call("FITS_CARD.getDbl","CDELT2"));
  else if ( unitsval == 3 ) coord[1] = (value/3600.0)/parseFloat(call("FITS_CARD.getDbl","CDELT2"));
  else if ( unitsval == 4 ) coord[1] = value;
  return coord;
} 

// TESTS 
ra_deg  = substring(data[1], 0, indexOf(data[1], "deg"));
dec_deg = substring(data[2], 0, indexOf(data[2], "deg"));
width_arcsec  = substring(data[4], 0, indexOf(data[4], "arcsec"));
height_arcsec = substring(data[5], 0, indexOf(data[5], "arcsec"));

system = "";
center_x = call("CONVERT_PIXELS_COORDINATES.coord2FitsX",ra_deg, dec_deg, system);
center_y = call("CONVERT_PIXELS_COORDINATES.coord2FitsY",ra_deg, dec_deg, system);
print("Pixel of first corner with CONVERT_PIXELS_COORDS = " + center_x + "  " + center_y);

ra_obtained = call("CONVERT_PIXELS_COORDINATES.fits2CoordXString",center_x, center_y, system);
dec_obtained = call("CONVERT_PIXELS_COORDINATES.fits2CoordYString",center_x, center_y, system);
print("RA of first corner with CONVERT_PIXELS_COORDS = " + ra_obtained + "  " + dec_obtained);

first_pixel = parseALMACoord (data[1], data[2]);
print("Pixel of first corner with parseALMAcoord = " + first_pixel[0] + "  " + first_pixel[1]);
width = parseALMAxy(data[4], data[5]);
left_pix = parseFloat(center_x) + parseFloat(width[0])/2;
left_ra = call("CONVERT_PIXELS_COORDINATES.fits2CoordXString",left_pix, center_y, system);
print("left side RA = " + left_ra);
bottom_pix = parseFloat(center_y) - parseFloat(width[1])/2;
bottom_ra = call("CONVERT_PIXELS_COORDINATES.fits2CoordYString",center_x, bottom_pix, system);
print("bottom side DEC = " + bottom_ra);



// // TEST MADCUBA CONVERT_PIXELS-COORDINATES. Seems that madcuba uses a string taken from the float, and the float gets rounded to 4 decimals.
// // When adding the fifth decimal 1 by 1, the float represented on screen is rounded correctly and ends up going up after 10 iterations
// float_short = 248.0953;
// float_long = 248.09532649;
// string_short = "248.0953";
// string_long = "248.09532649";
// print("Using the 4-decimal float :" + float_short + ", the pixel is: " + call("CONVERT_PIXELS_COORDINATES.coord2FitsX", float_short, dec1_deg, system));
// print("Using the 8-decimal float :" + float_long + ", the pixel is: " + call("CONVERT_PIXELS_COORDINATES.coord2FitsX", float_long, dec1_deg, system));
// print("Using the 4-decimal string :" + string_short + ", the pixel is: " + call("CONVERT_PIXELS_COORDINATES.coord2FitsX", string_short, dec1_deg, system));
// print("Using the 8-decimal string :" + string_long + ", the pixel is: " + call("CONVERT_PIXELS_COORDINATES.coord2FitsX", string_long, dec1_deg, system));

// // TESTS number of float decimals
// a = 0.00043443;

// for ( count = 0; count<30; count++ ){
//   print("0.00043443 + " + count + "=" + a);
//   a = a+0.00000001;
// }
