/* 
 * Custom made macro to convert CASA and CARTA ROIs to MADCUBA
 *
Possible ROIs:
Rectangular box; the two coordinates are two opposite corners:
     box[[x1, y1], [x2, y2]]
Center box; [x, y] define the center point of the box and [x_width, y_width] the width of the sides:
     centerbox[[x, y], [x_width, y_width]]
Rotated box; [x, y] define the center point of the box; [x_width, y_width] the width of the sides; rotang the rotation angle:
     rotbox[[x, y], [x_width, y_width], rotang]
Polygon; there could be many [x, y] corners; note that the last point will connect with the first point to close the polygon:
     poly[[x1, y1], [x2, y2], [x3, y3], ...]
Circle; center of the circle [x,y], r is the radius:
     circle[[x, y], r]
Annulus; center of the circle is [x, y], [r1, r2] are inner and outer radii:
     annulus[[x, y], [r1, r2]]
Ellipse; center of the ellipse is [x, y]; semi-axes are [b1, b2] starting with the vertical axis when first drawing the ellipse; 
     position angle of vertical axis is pa:
     ellipse[[x, y], [b1, b2], pa]
*/

coordUnits = newArray ("deg", "rad", "arcmin", "arcsec", "pix");
geometry = newArray ("box", "centerbox", "rotbox", "poly", "circle", "annulus", "ellipse"); 

path = File.openDialog("Select a Region File");
fx = File.openAsString(path);

rows = split(fx,"\n\r");      //Separate file into rows
for(i = 0; i< rows.length; i++){         //Iterate through csv list
     if (startsWith(rows[i] ,"#") ==0) {       //skip first line
          if (indexOf(rows[i], "coord=") !=-1) { 
               data = split(substring( rows[i] ,indexOf(rows[i], "coord="), indexOf(rows[i], "coord=")+30), "=,"); 
                    // search where the coord system is and store it at data[1]. +30 is arbitrary, to give enough characters for every possibility
               if (call("FITS_CARD.getStr","RADESYS") != data[1]) print ("WARNING:  Coordinate system in ALMA Roi different that that in cube");
          }
          data = split(rows[i],"][,");       // store different important data in an array. Some of these strings are preceded by a black space.
                                             // that is why later the 'if conditions' are not comparing data[0] () with strings, but locating the
                                             // position of the polygon string in the array data[0]. i.e data[0] is "rotbox " and not "rotbox"

          // print("New run");
          // for ( j = 0; j<data.length; j++ ){
          //      print("data[" + j +"]: '" + data[j] +"'");
          // }

          if (indexOf(data[0], geometry[0]) == 0) {    // BOX (CASA)
               b = parseALMACoord(data[1], data[2]);
               corr = 0.5;                        // a correction of half a pixel must be done. 
               x1 = parseFloat(b[0]) + corr;      // Madcuba sets the coordinates of a pixel in the lower left corner in a FITS image
               y1 = parseFloat(b[1]) + corr;      // with this correction it gets shifted to the center of the pixel
               b2 = parseALMACoord(data[4], data[5]);
               x_width = parseFloat(b2[0])-parseFloat(b[0]);
               y_width = parseFloat(b2[1])-parseFloat(b[1]);
               makeRectangle(x1, y1, x_width, y_width);     // Madcuba does the rounding when working with makeRectangle

          } else if (indexOf(data[0], geometry[1]) == 0) {  // CENTER BOX (CARTA)
               centro = parseALMACoord(data[1], data[2]);
               corr = 0.5;
               x_center = parseFloat(centro[0]) + corr;
               y_center = parseFloat(centro[1]) + corr;
               b = parseALMAxy(data[4], data[5]);
               x1 = x_center+parseFloat(b[0]/2); // + porque RA aumenta hacia izda y madcuba usa la esquina inferior izda del box.
               y1 = y_center-parseFloat(b[1]/2);
               x_width = -parseFloat(b[0]);  // - porque madcuba pone el ancho hacia la dcha como positivo, 
                                        // y el ancho en coordenadas de izda a dcha es cambio negativo.
               y_width = parseFloat(b[1]);
               makeRectangle(x1, y1, x_width, y_width);     // Madcuba does the rounding when working with makeRectangle

          } else if (indexOf(data[0], geometry[2]) == 0) {  // ROTATED BOX
               pa = parseALMAangle (data[6]);
               centro = parseALMACoord (data[1], data[2] );
               b = parseALMAxy (data[4], data[5]);
               rotatedRect(parseFloat(centro[0]), parseFloat(centro[1]), b[0]/2, b[1]/2, pa);

          } else if (indexOf(data[0], geometry[3]) == 0) {  // POLYGON
               indice =0;
               numb = 1;
               corr = 0.5;    // ImageJ starts counting from the top-left of each pixel. The same correction as with FITS must be applied here
               x = newArray(round(data.length/3));
               y = newArray(round(data.length/3));
               do {         
                    b = parseALMACoord(data[numb], data[numb+1]); 
                    x[indice]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX",b[0])) + corr;
                    y[indice]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY",b[1])) + corr;
                    indice = indice+1;
                    numb=numb+3; 
               } while (b[0] !=-1) 
               x=Array.trim(x, indice-1);    // Trim extra elements of the array that were created before
               y=Array.trim(y, indice-1);
               makeSelection("polygon", x, y);
               // Array.show(x, y);
 
          } else if (indexOf(data[0], geometry[4]) == 0) {  // CIRCLE 
               pa = 0;
               centro = parseALMACoord(data[1], data[2] );
               corr = 0.5;
               x_center = parseFloat(centro[0]) + corr;
               y_center = parseFloat(centro[1]) + corr;
               b = parseALMAxy(data[3], data[3]);
               toellipse(x_center, y_center, parseFloat(abs(b[0])), parseFloat(abs(b[1])), pa);
         
          } else if (indexOf(data[0], geometry[5]) == 0) {  // ANNULUS -------------------------- 
               centro = parseALMACoord (data[1], data[2] );
               b = parseALMAxy (data[3], data[3]);
               annulus(round(centro[0]), round(centro[1]), round(abs(b[0])), round(abs(b[1])));

          } else if (indexOf(data[0], geometry[6]) == 0) {  // ELLIPSE
               pa = parseALMAangle(data[6]);
               centro = parseALMACoord(data[1], data[2]);
               print(centro[0]);
               print(centro[1]);
               corr = 0.5;
               x_center = parseFloat(centro[0]) + corr;
               y_center = parseFloat(centro[1]) + corr;
               print(x_center);
               print(y_center);
               b = parseALMAxy(data[5], data[4]); // for an ellipse the first is y_width
               if (abs(b[0]) > abs(b[1])) {  // if x_width > y_width
                    bmaj = b[0];
                    bmin = b[1];
                    pa = pa-PI/2;  //change position angle to "change" x1, y1 to the biggest axis (madcuba accepts only ellipticity<=1)
               } else {
                    bmaj = b[1];
                    bmin = b[0];
               }
               toellipse(x_center, y_center, parseFloat(abs(bmaj)), parseFloat(abs(bmin)), pa);
          }
     }
}

/* 
 * ---------------------------------
 * ------ AUXILIARY FUNCTIONS ------
 * ---------------------------------
 */

function annulus(x, y, r1, r2) {
// angulo 0 en Norte 
     ar1 =    atan(2/r1);  //interior 
     ar2 =    atan(2/r2);  //exterior 
     number2 =2*PI/ar2;
     number1 = 2*PI/ar1;
     x1 = newArray(number2+number1+3);
     y1 = newArray(number2+number1+3);

     x1[0] = x+ r1;
     y1[0] = y;
     for(j = 0; j< number2; j++) { 
          x1[j+1]= x+r2*cos(j*ar2); 
          y1[j+1]= y+r2*sin(j*ar2); 
     }
     // print (y1[number2+1]);
     x1[number2+2] = x+r2; 
     y1[number2+2] =  y-1;
     // x1[number2+3] = x+r1; 
     // y1[number2+3] =  y-1;
      

     for(j = 0; j< number1; j++) { 
          k=j+number2+3;
          x1[k]= x+r1*cos(-j*ar1); 
          y1[k]= y-1+r1*sin(-j*ar1); 
     }
      
     x1[x1.length-1] = x+ r1;
     y1[x1.length-1] = y;
      
     for(j = 0; j<x1.length ; j++) { 
          x1[j] = call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x1[j]);
          y1[j] = call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y1[j]);

     
     }

     Array.show(x1, y1); 
     makeSelection("polygon", x1, y1); 
}

function rotatedRect(x, y, halfWidth, halfHeight, angle) {
     x1 = newArray(4);
     y1 = newArray(4);
     c = cos(angle);
     s = sin(angle);
     r1x = -halfWidth * c - halfHeight * s;
     r1y = -halfWidth * s + halfHeight * c;
     r2x =  halfWidth * c - halfHeight * s;
     r2y =  halfWidth * s + halfHeight * c;
     corr = 0.5;    // madcuba starts counting the pixels on the left and the top of each pixel for ImageJXY coords
     // Returns four points in clockwise order starting from the top left.
     x1[0]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r1x)) + corr;
     x1[1]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r2x)) + corr; 
     x1[2]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r1x)) + corr; 
     x1[3]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r2x)) + corr; 
     y1[0]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r1y)) + corr;
     y1[1]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r2y)) + corr;
     y1[2]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r1y)) + corr;
     y1[3]=parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r2y)) + corr;
     makeSelection("polygon", x1, y1);
     // Array.show(x1, y1); 
}

function toellipse (x, y, bmaj, bmin, pa){
     // all parameters in pixels except pa in radians 
     x1 = x+bmaj*sin(pa);
     y1 = y-bmaj*cos(pa);
     x2 = x-bmaj*sin(pa);
     y2 = y+bmaj*cos(pa);
     e = bmin/bmaj;
     makeEllipse(x1,y1,x2,y2,e); 
     // split(data[4], "deg");     // Jesus put this here but it does nothing of value?
}

function parseALMAangle (val) {
     // Returns the angle in radians

     coordUnits = newArray ("deg", "rad", "arcmin", "arcsec");      
    
     for(j = 0; j< coordUnits.length; j++) { if (indexOf(val, coordUnits[j]) !=-1)  unitsval=j;}
     angle = parseFloat (substring(val, 0, indexOf(val, coordUnits[unitsval])));  
     if ( unitsval == 0 )  angle = angle*PI/180.0;
     else if ( unitsval == 2 ) angle = (angle*PI/(180.0*60.0));
     else if ( unitsval == 3 ) angle = (angle*PI/(180.0*3600.0));
     return angle;
} 

function parseALMACoord (ra, dec) {
     // Convert coordinates to pixel 
     coordUnits = newArray ("deg", "rad", "pix");
     unitsval= 10;
     output = newArray(2);
     for(j = 0; j< coordUnits.length; j++) { if (indexOf(ra, coordUnits[j]) !=-1)  unitsval=j;}  // read coordinate unit
     if (unitsval == 10) {   // Sexagesimal Coordinates
          // TEMPORARY. Quick abortion of function for the polygon drawing. May be better put in another simpler and more coherent way.
          // Temporary in here because unitsval gets assigned 10 and the last iteration in the 'while' loop enters here. It has to yoild -1.   
          if (indexOf(ra, "corr") == 0 || indexOf(ra, "corr") == 1) {
               output[0] = -1;
               output[1] = -1;
          } else {
               // right ascension
               par = split(ra,"hdms:"); 
               if (par.length ==1 && indexOf(ra, ".") <=5 ) {
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
 
