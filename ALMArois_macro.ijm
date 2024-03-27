/* 
 * Custom made macro to convert CASA and CARTA ROIs to MADCUBA
 * A cube or image must be opened and selected before running this macro
 *
 * Possible ROIs:
 * Rectangular box; the two coordinates are two opposite corners:
 *     box[[x1, y1], [x2, y2]]
 * Center box; [x, y] define the center point of the box and [x_width, y_width] the width of the sides:
 *     centerbox[[x, y], [x_width, y_width]]
 * Rotated box; [x, y] define the center point of the box; [x_width, y_width] the width of the sides; rotang the rotation angle:
 *     rotbox[[x, y], [x_width, y_width], rotang]
 * Polygon; there could be many [x, y] corners; note that the last point will connect with the first point to close the polygon:
 *     poly[[x1, y1], [x2, y2], [x3, y3], ...]
 * Circle; center of the circle [x,y], r is the radius:
 *     circle[[x, y], r]
 * Annulus; center of the circle is [x, y], [r1, r2] are inner and outer radii:
 *     annulus[[x, y], [r1, r2]]
 * Ellipse; center of the ellipse is [x, y]; semi-axes are [b1, b2] starting with the vertical axis when first drawing the ellipse; 
 *     position angle of vertical axis is pa:
 *     ellipse[[x, y], [b1, b2], pa]
 */

// Global variables
var coordUnits = newArray ("deg", "rad", "arcmin", "arcsec", "pix");
var geometry = newArray ("box", "centerbox", "rotbox", "poly", "circle", "annulus", "ellipse");

macro "Import ROIs" {
    path = File.openDialog("Select a Region File");
    fx = File.openAsString(path);

    rows = split(fx,"\n\r");                    //Separate file into rows
    for (i=0; i<rows.length; i++) {             //Iterate through csv list
        if (startsWith(rows[i],"#") == 0) {     //skip first line
            if (indexOf(rows[i], "coord=") != -1) { 
                data = split(substring(rows[i], indexOf(rows[i], "coord="), indexOf(rows[i], "coord=")+30), "=,"); 
                        // search where the coord system is and store it at data[1]. +30 is arbitrary, to give enough characters for every possibility
                if (call("FITS_CARD.getStr","RADESYS") != data[1]) print("WARNING:  Coordinate system in ALMA Roi different that that in cube");
            }
            data = split(rows[i], "][,");   // store different important data in an array. Some of these strings are preceded by a black space.
                                            // that is why later the 'if conditions' are not comparing data[0] () with strings, but locating the
                                            // position of the polygon string in the array data[0]. i.e data[0] is "rotbox " and not "rotbox"
            
            // // Uncomment for quick data debug
            // print("New run");
            // for (j=0; j<data.length; j++) {
            //     print("data[" + j + "]: '" + data[j] + "'");
            // }

            if (indexOf(data[0], geometry[0]) == 0) {           // BOX (CASA)
                corner1 = parseALMACoord(data[1], data[2]);
                corner2 = parseALMACoord(data[4], data[5]);
                corr = 0.5;                             // a correction of half a pixel must be done
                x1 = parseFloat(corner1[0]) + corr;     // Madcuba sets the coordinates of a pixel in the lower left corner in a FITS image
                y1 = parseFloat(corner1[1]) + corr;     // with this correction it gets shifted to the center of the pixel
                x2 = parseFloat(corner2[0]) + corr;
                y2 = parseFloat(corner2[1]) + corr;
                x_width = x2 - x1;
                y_width = y2 - y1;
                makeRectangle(x1, y1, x_width, y_width);    // Madcuba does the rounding when working with makeRectangle

            } else if (indexOf(data[0], geometry[1]) == 0) {    // CENTER BOX (CARTA)
                center = parseALMACoord(data[1], data[2]);
                corr = 0.5;
                x_center = parseFloat(center[0]) + corr;
                y_center = parseFloat(center[1]) + corr;
                widths = parseALMAxy(data[4], data[5]);
                x1 = x_center + parseFloat(widths[0]/2);    // + because RA increases to the left and madcuba uses the lower left corner
                y1 = y_center - parseFloat(widths[1]/2);
                x_width = -parseFloat(widths[0]);   // - because parseALMAxy calculated a positive width to the left 
                                                    //and madcuba needs a width to the right of the rectangle
                y_width = parseFloat(widths[1]);
                makeRectangle(x1, y1, x_width, y_width);    // Madcuba does the rounding when working with makeRectangle

            } else if (indexOf(data[0], geometry[2]) == 0) {    // ROTATED BOX
                pa = parseALMAangle(data[6]);
                center = parseALMACoord(data[1], data[2]);
                b = parseALMAxy(data[4], data[5]);
                rotatedRect(parseFloat(center[0]), parseFloat(center[1]), b[0]/2, b[1]/2, pa);

            } else if (indexOf(data[0], geometry[3]) == 0) {    // POLYGON
                idx = 0;
                numb = 1;
                corr = 0.5;     // ImageJ starts counting from the top-left of each pixel. The same correction as with FITS must be applied here
                x = newArray(round(data.length/3));
                y = newArray(round(data.length/3));
                do {         
                    b = parseALMACoord(data[numb], data[numb+1]); 
                    x[idx] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", b[0])) + corr;
                    y[idx] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", b[1])) + corr;
                    idx++;
                    numb = numb + 3;        // Jump to the next polygon vertex. The data object is separated: ...[Xn], [Yn], [. ], [Xn+1], [Yn+1], [. ]...
                } while (b[0] != -1) 
                x = Array.trim(x, idx-1);   // Trim extra elements of the array that were created before
                y = Array.trim(y, idx-1);
                makeSelection("polygon", x, y);
                // Array.show(x, y);
    
            } else if (indexOf(data[0], geometry[4]) == 0) {    // CIRCLE 
                pa = 0;
                center = parseALMACoord(data[1], data[2] );
                corr = 0.5;
                x_center = parseFloat(center[0]) + corr;
                y_center = parseFloat(center[1]) + corr;
                radius = parseALMAxy(data[3], data[3]);
                toellipse(x_center, y_center, parseFloat(abs(radius[0])), parseFloat(abs(radius[1])), pa);
            
            } else if (indexOf(data[0], geometry[5]) == 0) {    // ANNULUS -------------------------- 
                center = parseALMACoord(data[1], data[2]);
                corr = 0.5;
                x_center = parseFloat(center[0]) + corr;
                y_center = parseFloat(center[1]) + corr;
                r1 = parseALMAxy(data[3], data[3]);
                r2 = parseALMAxy(data[4], data[4]);
                x2 = x_center - parseFloat(r2[1]);   // outer circle
                y2 = y_center - parseFloat(r2[1]);
                makeOval(x2, y2, r2[1]*2, r2[1]*2);
                x1 = x_center - parseFloat(r1[1]);   // inner circle
                y1 = y_center - parseFloat(r1[1]);
                setKeyDown("alt");
                makeOval(x1, y1, r1[1]*2, r1[1]*2);
                // annulus(round(center[0]), round(center[1]), round(abs(b[0])), round(abs(b[1])));    // old version

            } else if (indexOf(data[0], geometry[6]) == 0) {    // ELLIPSE
                pa = parseALMAangle(data[6]);
                center = parseALMACoord(data[1], data[2]);
                corr = 0.5;
                x_center = parseFloat(center[0]) + corr;
                y_center = parseFloat(center[1]) + corr;
                axes = parseALMAxy(data[5], data[4]);   // for an ellipse the first is y_width
                if (abs(axes[0]) > abs(axes[1])) {      // if x_width > y_width
                    bmaj = axes[0];
                    bmin = axes[1];
                    pa = pa-PI/2;  //change position angle to "change" x1, y1 to the biggest axis (madcuba accepts only ellipticity<=1)
                } else {
                    bmaj = axes[1];
                    bmin = axes[0];
                }
                toellipse(x_center, y_center, parseFloat(abs(bmaj)), parseFloat(abs(bmin)), pa);
            }
        }
    }
}


/* 
 * ---------------------------------
 * ------ AUXILIARY FUNCTIONS ------
 * ---------------------------------
 */

// function annulus(x, y, r1, r2) {
// // angulo 0 en Norte 
//     ar1 = atan(2/r1);  //interior 
//     ar2 = atan(2/r2);  //exterior 
//     number2 = 2*PI/ar2;
//     number1 = 2*PI/ar1;
//     x1 = newArray(number2+number1+3);
//     y1 = newArray(number2+number1+3);

//     x1[0] = x + r1;
//     y1[0] = y;
//     for (j=0; j<number2; j++) { 
//         x1[j+1]= x + r2*cos(j*ar2); 
//         y1[j+1]= y + r2*sin(j*ar2); 
//     }
//     // print (y1[number2+1]);
//     x1[number2+2] = x + r2; 
//     y1[number2+2] = y - 1;
//     // x1[number2+3] = x+r1; 
//     // y1[number2+3] =  y-1;
      

//     for (j=0; j<number1; j++) { 
//         k = j+number2+3;
//         x1[k]= x + r1*cos(-j*ar1); 
//         y1[k]= y - 1 + r1*sin(-j*ar1); 
//     }
      
//     x1[x1.length-1] = x + r1;
//     y1[x1.length-1] = y;
      
//     for (j=0; j<x1.length; j++) { 
//         x1[j] = call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x1[j]);
//         y1[j] = call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y1[j]);
//     }

//     Array.show(x1, y1); 
//     makeSelection("polygon", x1, y1); 
// }

/** 
 * Draw a rotated rectangle given the input parameters
 * All parameters are in pixels except angle in radians
 * 
 * @param x  X coordinates for the center of the rectangle
 * @param y  Y coordinates for the center of the rectangle
 * @param halfWidth  Half of the width of the rectangle
 * @param halfHeight  Half of the height of the rectangle
 * @param angle  Rotation Angle in a counterclockwise direction
 */
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
    x1[0] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r1x)) + corr;
    x1[1] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r2x)) + corr; 
    x1[2] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r1x)) + corr; 
    x1[3] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r2x)) + corr; 
    y1[0] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r1y)) + corr;
    y1[1] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r2y)) + corr;
    y1[2] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r1y)) + corr;
    y1[3] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r2y)) + corr;
    makeSelection("polygon", x1, y1);
    // Array.show(x1, y1); 
}

/** 
 * Draw ellipse given the input parameters
 * All parameters are in pixels except pa in radians
 * 
 * @param x  X coordinates for the center of the ellipse
 * @param y  Y coordinates for the center of the ellipse
 * @param bmaj  Major axis
 * @param bmin  Minor axis
 * @param pa  Position Angle of the major axis in a counterclockwise direction
 */
function toellipse(x, y, bmaj, bmin, pa) {
    x1 = x + bmaj*sin(pa);
    y1 = y - bmaj*cos(pa);
    x2 = x - bmaj*sin(pa);
    y2 = y + bmaj*cos(pa);
    e = bmin/bmaj;
    makeEllipse(x1, y1, x2, y2, e); 
    // split(data[4], "deg");     // Jesus put this here but it does nothing of value?
}

/** 
 * Convert angle to radians
 * 
 * @param val  Input angle with units 
 * @return  Converted angle in radians
 */
function parseALMAangle (val) {
    coordUnits = newArray("deg", "rad", "arcmin", "arcsec");      
    for (j=0; j<coordUnits.length; j++) if (indexOf(val, coordUnits[j]) != -1)  unitsval=j;     // read coordinate unit
    angle = parseFloat(substring(val, 0, indexOf(val, coordUnits[unitsval])));  
    if (unitsval == 0)  angle = angle*PI/180.0;
    else if (unitsval == 2) angle = (angle*PI/(180.0*60.0));
    else if (unitsval == 3) angle = (angle*PI/(180.0*3600.0));
    return angle;
} 

/**
 * Convert coordinates to a FITS image pixel 
 * 
 * @param ra  RA with units
 * @param dec  DEC with units
 * @return  Pixel of the image containing input coordinates
 */
function parseALMACoord (ra, dec) {
    coordUnits = newArray ("deg", "rad", "pix");
    unitsval= 10;
    output = newArray(2);
    for (j=0; j<coordUnits.length; j++) if (indexOf(ra, coordUnits[j]) != -1) unitsval=j;       // read coordinate unit
    if (unitsval == 10) {   // Sexagesimal Coordinates
        // TEMPORARY. Quick abortion of function for the polygon drawing. May be better put in another simpler and more coherent way.
        // Temporary in here because unitsval gets assigned 10 and the last iteration in the 'while' loop enters here. It has to yoild -1.   
        if (indexOf(ra, "corr") == 0 || indexOf(ra, "corr") == 1) {
            output[0] = -1;
            output[1] = -1;
        } else {
            // right ascension
            par = split(ra, "hdms:"); 
            if (par.length == 1 && indexOf(ra, ".") <= 5) {
                par = split(ra, "."); 
                if (par.length > 3) par[2] = par[2] + "." + par[3]; 
            } 
            rafin = (parseFloat(par[0]) + parseFloat(par[1])/60.0 + parseFloat(par[2])/3600.0) * 15.0;
            // declination
            par = split(dec, "hdms:"); 
            if (par.length == 1 && indexOf(dec, ".") <= 5) {
                par = split(dec,"."); 
                if (par.length > 3) par[2] = par[2] + "." + par[3]; 
            } 
            if (indexOf(dec, "-") != -1) decfin = parseFloat(par[0]) - parseFloat(par[1])/60.0 - parseFloat(par[2])/3600.0;
            else decfin = parseFloat(par[0]) + parseFloat(par[1])/60.0 + parseFloat(par[2])/3600.0;
     
            output[0] = call("CONVERT_PIXELS_COORDINATES.coord2FitsX", rafin, decfin, ""); 
            output[1] = call("CONVERT_PIXELS_COORDINATES.coord2FitsY", rafin, decfin, ""); 
        }
    } else { 
        rafin = substring(ra, 0, indexOf(ra, coordUnits[unitsval]));   // there was a parseFloat here but it deleted many decimals and got incorrect results
        decfin = substring(dec, 0, indexOf(dec, coordUnits[unitsval])); // here too
        if (unitsval == 0 || unitsval == 1) {
            if (unitsval == 1) {
                rafin =  rafin*180.0/PI;
                decfin = decfin*180.0/PI;
            }
            output[0] = call("CONVERT_PIXELS_COORDINATES.coord2FitsX", rafin, decfin, ""); 
            output[1] = call("CONVERT_PIXELS_COORDINATES.coord2FitsY", rafin, decfin, ""); 

        } else if ( unitsval == 2) {
            output[0] = rafin;
            output[1] = decfin;
        }      
    }
    return output; 
} 

/**
 * Convert an arc in the sky to pixels
 * 
 * @param valx  RA arc in the sky with units 
 * @param valy  DEC arc in the sky with units
 * @return  Converted arc
 */
function parseALMAxy (valx,valy) {
    coordUnits = newArray("deg", "rad", "arcmin", "arcsec", "pix");  
    unitsval = -1;
    coord = newArray(2);
    coord[0] = -1;

    for (j=0; j<coordUnits.length; j++) if (indexOf(valx, coordUnits[j]) != -1)  unitsval=j;    // read coordinate unit
    if (unitsval == -1) return coord;   // case of request without unit to use with polygon

    value = parseFloat (substring(valx, 0, indexOf(valx, coordUnits[unitsval])));  
    if      (unitsval == 0) coord[0] = value / parseFloat(call("FITS_CARD.getDbl","CDELT1"));
    else if (unitsval == 1) coord[0] = (value*180.0/PI) / parseFloat(call("FITS_CARD.getDbl","CDELT1"));
    else if (unitsval == 2) coord[0] = (value/60.0) / parseFloat(call("FITS_CARD.getDbl","CDELT1"));
    else if (unitsval == 3) coord[0] = (value/3600.0) / parseFloat(call("FITS_CARD.getDbl","CDELT1"));
    else if (unitsval == 4) coord[0] = value;

    for (j=0; j<coordUnits.length; j++) if (indexOf(valy, coordUnits[j]) != -1)  unitsval=j;    // read coordinate unit
    value = parseFloat(substring(valy, 0, indexOf(valy, coordUnits[unitsval])));  
    if      (unitsval == 0) coord[1] = value / parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    else if (unitsval == 1) coord[1] = (value*180.0/PI) / parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    else if (unitsval == 2) coord[1] = (value/60.0) / parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    else if (unitsval == 3) coord[1] = (value/3600.0) / parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    else if (unitsval == 4) coord[1] = value;
    return coord;
}