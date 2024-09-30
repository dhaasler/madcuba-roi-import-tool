/* 
 * Custom made macro to convert CASA and CARTA ROIs to MADCUBA
 * A cube or image must be opened and selected before running this macro
 *
 * Possible ROIs:
 * Point as coordinates:
 *     symbol [x, y]
 * Line; the two coordinates are the vertices:
 *     line [[x1, y1], [x2, y2]]
 * Polyline; there could be many [x, y] vertices:
 *     polyline [[x1, y1], [x2, y2], [x3, y3], ...] 
 * Rectangular box; the two coordinates are two opposite corners:
 *     box [[x1, y1], [x2, y2]]
 * Center box; [x, y] define the center point of the box and [x_width, y_width]
 *     the width of the sides:
 *     centerbox [[x, y], [x_width, y_width]]
 * Rotated box; [x, y] define the center point of the box; [x_width, y_width]
 *     the width of the sides; rotang the rotation angle:
 *     rotbox [[x, y], [x_width, y_width], rotang]
 * Polygon; there could be many [x, y] corners; note that the last point will
 *     connect with the first point to close the polygon:
 *     poly [[x1, y1], [x2, y2], [x3, y3], ...]
 * Circle; center of the circle [x,y], r is the radius:
 *     circle [[x, y], r]
 * Annulus; center of the circle is [x, y], [r1, r2] are inner and outer radii:
 *     annulus [[x, y], [r1, r2]]
 * Ellipse; center of the ellipse is [x, y]; semi-axes are [b1, b2] starting
 *     with the vertical axis when first drawing the ellipse; position angle of 
 *     vertical axis is pa:
 *     ellipse [[x, y], [b1, b2], pa]
 */

var version = "v1.2";
var date = "20240930";
var changelog = "Add support for DS9 regions.";

// Global variables
var coordUnits = newArray ("deg", "rad", "arcmin", "arcsec", "pix");

macro "Import ROIs from CARTA Action Tool - C037 T0608L T4608O Ta608A Tf608D T2f10R T8f09o Tef09I" {
       // RoI: C037T0b10R T6b09o Tcb09I

    path = File.openDialog("Select a ROI File");
    fx = File.openAsString(path);

    rows = split(fx,"\n\r");                    // separate file into rows
    
    if (startsWith(rows[0],"#CRTF") == 1) {     // CRTF file
        /* search the coord system string and store it */
        if (indexOf(rows[1], "coord=") != -1) {
            coordSystem = split(substring(rows[1], indexOf(rows[1],
                                            "coord=")), "=,");
            if (call("FITS_CARD.getStr","RADESYS") != coordSystem[1]) 
                print("WARNING:  Coordinate system in ALMA Roi different "
                        + "than that in cube");
        }
        /* Separate the data into an array, data[0] contains the RoI type
        Some of these strings are preceded or followed by a blank space. 
        That is why later the 'if' conditions are not comparing data[0]
        with strings, but locating the position of the polygon string in 
        the array data[0] (i.e data[0] is "rotbox " and not "rotbox") */
        data = split(rows[1], "][,");

        // /* uncomment for quick data log */
        // print("New run");
        // for (j=0; j<data.length; j++) {
        //     print("data[" + j + "]: '" + data[j] + "'");
        // }

        importCrtfRoi(data);
        run("GET SPECTRUM", "roi");
    }

    if (startsWith(rows[0],"# Region file format: DS9") == 1) {     // DS9 file
        /* search the coord system units string (icrs or image) and store it */
        coordUnitSystem = rows[2];

        /* Separate the data into an array, data[0] contains the RoI type
        Some of these strings are preceded or followed by a blank space. 
        That is why later the 'if' conditions are not comparing data[0]
        with strings, but locating the position of the polygon string in 
        the array data[0] (i.e data[0] is "rotbox " and not "rotbox") */
        data = split(rows[3], ")(,");

        // /* uncomment for quick data log */
        // print("New run");
        // print(coordUnitSystem);
        // for (j=0; j<data.length; j++) {
        //     print("data[" + j + "]: '" + data[j] + "'");
        // }

        importDs9Roi(data, coordUnitSystem);
        run("GET SPECTRUM", "roi");
    }

}

macro "Import ROIs from CARTA Action Tool Options" {
    showMessage("Info", "<html>"
    + "<center><h2>ROI Import Tool</h2></center>"
    + "Custom made tool to import CASA, CARTA, and DS9 ROIs into MADCUBA.<br><br>"
    + "<strong>Important</strong>: A cube or image must be opened and selected "
    + "before running this macro. <br><br>"
    + "<h3>Changelog</h3>"
    + "<font size=-1>"
    + version + " - " + date + " <br>"
    + changelog);
}

/*
 * ---------------------------------
 * ---------------------------------
 * ------ AUXILIARY FUNCTIONS ------
 * ---------------------------------
 * ---------------------------------
 */


/**
 * Parse a crtf data list and create a madcuba ROI
 * 
 * @param data  Data list containing ROI parameters
 */
function importCrtfRoi(data) {

    geometry = newArray ("symbol", "line", "polyline", "box", "centerbox", 
                         "rotbox", "poly", "circle", "annulus", "ellipse"); 
    /* POINT */
    if (indexOf(data[0], geometry[0]) == 0) {
        point = parseCrtfCoords(data[1], data[2]);
        x = parseFloat(point[0]);
        y = parseFloat(point[1]);
        makePoint(x, y);
        // print("painted: " + x + ", " + y);
    
    /* LINE */
    } else if (indexOf(data[0], geometry[1]) == 0) {
        point1 = parseCrtfCoords(data[1], data[2]);
        x1 = parseFloat(point1[0]);
        y1 = parseFloat(point1[1]);
        point2 = parseCrtfCoords(data[4], data[5]);
        x2 = parseFloat(point2[0]);
        y2 = parseFloat(point2[1]);
        makeLine(x1, y1, x2, y2);
        // print("from: " + x1 + ", " + y1);
        // print("to: " + x2 + ", " + y2);
    
    /* POLYLINE (almost the same as polygon) */
    } else if (indexOf(data[0], geometry[2]) == 0) {
        stop = 0;
        idx = 0;    // index of points
        numb = 1;   // index from which to start reading data array
        x = newArray(round(data.length/3));
        y = newArray(round(data.length/3));
        do {         
            b = parseCrtfCoords(data[numb], data[numb+1]); 
            x[idx] = 
                parseFloat(call(
                    "CONVERT_PIXELS_COORDINATES.fits2ImageJX", b[0]));
            y[idx] = 
                parseFloat(call(
                    "CONVERT_PIXELS_COORDINATES.fits2ImageJY", b[1]));
            /* stop when a double ]] appears in the ROI file (at the end
            of the vertices). In the ROI file when ]] appears, the next
            item is not a blank space, but a new keyword */
            if (data[numb+2] != " ") {
                stop=1;
            }
            idx++;
            /* Jump to the next polygon vertex. The data object is 
            separated: ...[Xn], [Yn], [ ], [Xn+1], [Yn+1], [ ]... */
            numb = numb + 3;
        } while (stop != 1)
        /* trim extra elements of the array that were created before */
        x = Array.trim(x, idx);
        y = Array.trim(y, idx);
        makeSelection("polyline", x, y);
        // Array.show(x, y);

    /* BOX (CASA) */
    } else if (indexOf(data[0], geometry[3]) == 0) {
        corner1 = parseCrtfCoords(data[1], data[2]);
        corner2 = parseCrtfCoords(data[4], data[5]);
        x1 = parseFloat(corner1[0]);
        y1 = parseFloat(corner1[1]);
        x2 = parseFloat(corner2[0]);
        y2 = parseFloat(corner2[1]);
        x_width = x2 - x1;
        y_width = y2 - y1;
        /* MADCUBA does the rounding when working with makeRectangle */
        makeRectangle(x1, y1, x_width, y_width);

    /* CENTER BOX (CARTA) */
    } else if (indexOf(data[0], geometry[4]) == 0) {
        center = parseCrtfCoords(data[1], data[2]);
        x_center = parseFloat(center[0]);
        y_center = parseFloat(center[1]);
        width = parseCrtfArcLength(data[4]);
        height = parseCrtfArcLength(data[5]);
        x1 = x_center - parseFloat(width/2);
        y1 = y_center - parseFloat(height/2);
        x_width = parseFloat(width);
        y_width = parseFloat(height);
        /* MADCUBA does the rounding when working with makeRectangle */
        makeRectangle(x1, y1, x_width, y_width);

    /* ROTATED BOX */
    } else if (indexOf(data[0], geometry[5]) == 0) {
        pa = parseCrtfAngle(data[6]);
        center = parseCrtfCoords(data[1], data[2]);
        b1 = parseCrtfArcLength(data[4]);
        b2 = parseCrtfArcLength(data[5]);
        rotatedRect(parseFloat(center[0]), parseFloat(center[1]),
                    b1/2, b2/2, pa);

    /* POLYGON */
    } else if (indexOf(data[0], geometry[6]) == 0) {
        stop = 0;
        idx = 0;    // index of points
        numb = 1;   // index from which to start reading data array
        x = newArray(round(data.length/3));
        y = newArray(round(data.length/3));
        do {
            b = parseCrtfCoords(data[numb], data[numb+1]); 
            x[idx] = 
                parseFloat(call(
                    "CONVERT_PIXELS_COORDINATES.fits2ImageJX", b[0]));
            y[idx] = 
                parseFloat(call(
                    "CONVERT_PIXELS_COORDINATES.fits2ImageJY", b[1]));
            /* stop when a double ]] appears in the ROI file (at the end
            of the vertices). In the ROI file when ]] appears it has no
            space afterwards, but a new keyword */
            if (data[numb+2] != " ") {
                stop=1;
            }
            idx++;
            /* Jump to the next polygon vertex. The data object is 
            separated: ...[Xn], [Yn], [. ], [Xn+1], [Yn+1], [. ]... */
            numb = numb + 3;
        } while (stop != 1)
        /* trim extra elements of the array that were created before if
        the crtf file has more parameters at the end */
        x2 = Array.trim(x, idx);
        y2 = Array.trim(y, idx);
        makeSelection("polygon", x2, y2);
        // Array.show(x, y, x2, y2);

    /* CIRCLE  */
    } else if (indexOf(data[0], geometry[7]) == 0) {
        pa = 0;
        center = parseCrtfCoords(data[1], data[2] );
        xCenter = parseFloat(center[0]);
        yCenter = parseFloat(center[1]);
        radius = parseCrtfArcLength(data[3]);
        toEllipse(xCenter, yCenter, parseFloat(abs(radius)),
                    parseFloat(abs(radius)), pa);
        
    /* ANNULUS */
    } else if (indexOf(data[0], geometry[8]) == 0) {
        center = parseCrtfCoords(data[1], data[2]);
        xCenter = parseFloat(center[0]);
        yCenter = parseFloat(center[1]);
        r1 = parseCrtfArcLength(data[3]);
        r2 = parseCrtfArcLength(data[4]);
        x2 = xCenter - parseFloat(r2);   // outer circle
        y2 = yCenter - parseFloat(r2);
        makeOval(x2, y2, r2*2, r2*2);
        x1 = xCenter - parseFloat(r1);   // inner circle
        y1 = yCenter - parseFloat(r1);
        setKeyDown("alt");
        makeOval(x1, y1, r1*2, r1*2);
        setKeyDown("none");

    /* ELLIPSE */
    } else if (indexOf(data[0], geometry[9]) == 0) {
        pa = parseCrtfAngle(data[6]);
        center = parseCrtfCoords(data[1], data[2]);
        xCenter = parseFloat(center[0]);
        yCenter = parseFloat(center[1]);
        /* For an ellipse the first axis in the code is the Yaxis.
            * Lets change the order to have Xaxis first and then Yaxis. */
        ax_y = parseCrtfArcLength(data[4]);
        ax_x = parseCrtfArcLength(data[5]);
        /* Set the major axis and convert the position angle if needed.
        In 'toEllipse' the position angle is that of the major axis, but
        in CARTA it is the angle of the Y-axis. The position angle must
        be transformed to the angle of the biggest axis. Which is simply
        rotating it 90 degrees if the X-axis is the major axis */
        if (abs(ax_x) > abs(ax_y)) {
            bmaj = ax_x;
            bmin = ax_y;
            pa = pa-PI/2;
        } else {
            bmaj = ax_y;
            bmin = ax_x;
        }
        toEllipse(xCenter, yCenter, parseFloat(abs(bmaj)), 
                    parseFloat(abs(bmin)), pa);
    } else {
        exit("Error: CRTF RoI type <" + data[0] + "> not recognized.");
    }
}


/**
 * Parse a crtf data list and create a madcuba ROI
 * 
 * @param data  Data list containing ROI parameters
 */
function importDs9Roi(data, coordUnitSystem) {

    geometry = newArray ("point", "line", "polyline", "box",  
                         "polygon", "circle", "ellipse"); 
    /* POINT */
    if (indexOf(data[0], geometry[0]) == 0) {
        point = parseDs9Coords(data[1], data[2], coordUnitSystem);
        x = parseFloat(point[0]);
        y = parseFloat(point[1]);
        makePoint(x, y);
        // print("painted: " + x + ", " + y);
    
    /* LINE */
    } else if (indexOf(data[0], geometry[1]) == 0) {
        point1 = parseDs9Coords(data[1], data[2], coordUnitSystem);
        x1 = parseFloat(point1[0]);
        y1 = parseFloat(point1[1]);
        point2 = parseDs9Coords(data[3], data[4], coordUnitSystem);
        x2 = parseFloat(point2[0]);
        y2 = parseFloat(point2[1]);
        makeLine(x1, y1, x2, y2);
        // print("from: " + x1 + ", " + y1);
        // print("to: " + x2 + ", " + y2);
    
    /* POLYLINE (almost the same as polygon) */
    } else if (indexOf(data[0], geometry[2]) == 0) {
        stop = 0;
        idx = 0;    // index of points
        numb = 1;   // index from which to start reading data array
        x = newArray(round(data.length/2));
        y = newArray(round(data.length/2));
        do {         
            b = parseDs9Coords(data[numb], data[numb+1], coordUnitSystem); 
            x[idx] = 
                parseFloat(call(
                    "CONVERT_PIXELS_COORDINATES.fits2ImageJX", b[0]));
            y[idx] = 
                parseFloat(call(
                    "CONVERT_PIXELS_COORDINATES.fits2ImageJY", b[1]));
            /* stop when # appears in the ROI file (at the end
            of the vertices). */
            if (startsWith(data[numb+2]," #") == 1) {
                stop=1;
            }
            idx++;
            /* Jump to the next polygon vertex. The data object is 
            separated: ...Xn, Yn, Xn+1, Yn+1, ... */
            numb = numb + 2;
        } while (stop != 1)
        /* trim extra elements of the array that were created before */
        x = Array.trim(x, idx);
        y = Array.trim(y, idx);
        makeSelection("polyline", x, y);
        // Array.show(x, y);

    /* BOX (rotation=0) */
    } else if ((indexOf(data[0], geometry[3]) == 0)) {
        if ((data[5] == "0") || (data[5] == " 0")) {  // ROTATION=0
            center = parseDs9Coords(data[1], data[2], coordUnitSystem);
            x_center = parseFloat(center[0]);
            y_center = parseFloat(center[1]);
            width = parseDs9ArcLength(data[3], coordUnitSystem);
            height = parseDs9ArcLength(data[4], coordUnitSystem);
            x1 = x_center - parseFloat(width/2);
            y1 = y_center - parseFloat(height/2);
            x_width = parseFloat(width);
            y_width = parseFloat(height);
            /* MADCUBA does the rounding when working with makeRectangle */
            makeRectangle(x1, y1, x_width, y_width);
        } else if ((data[5] != "0") && (data[5] != " 0")) {  // ROTATED
            pa = parseDs9Angle(data[5]);
            center = parseDs9Coords(data[1], data[2], coordUnitSystem);
            b1 = parseDs9ArcLength(data[3], coordUnitSystem);
            b2 = parseDs9ArcLength(data[4], coordUnitSystem);
            rotatedRect(parseFloat(center[0]), parseFloat(center[1]),
                        b1/2, b2/2, pa);
        }

    /* POLYGON */
    } else if (indexOf(data[0], geometry[4]) == 0) {
        stop = 0;
        idx = 0;    // index of points
        numb = 1;   // index from which to start reading data array
        x = newArray(round(data.length/2));
        y = newArray(round(data.length/2));
        do {
            b = parseDs9Coords(data[numb], data[numb+1], coordUnitSystem); 
            x[idx] = 
                parseFloat(call(
                    "CONVERT_PIXELS_COORDINATES.fits2ImageJX", b[0]));
            y[idx] = 
                parseFloat(call(
                    "CONVERT_PIXELS_COORDINATES.fits2ImageJY", b[1]));
            /* stop when # appears in the ROI file (at the end
            of the vertices). */
            if (startsWith(data[numb+2]," #") == 1) {
                stop=1;
            }
            idx++;
            /* Jump to the next polygon vertex. The data object is 
            separated: ...Xn, Yn, Xn+1, Yn+1, ... */
            numb = numb + 2;
        } while (stop != 1)
        /* trim extra elements of the array that were created before if
        the crtf file has more parameters at the end */
        x2 = Array.trim(x, idx);
        y2 = Array.trim(y, idx);
        makeSelection("polygon", x2, y2);
        // Array.show(x, y, x2, y2);

    /* CIRCLE  */
    } else if (indexOf(data[0], geometry[5]) == 0) {
        pa = 0;
        center = parseDs9Coords(data[1], data[2], coordUnitSystem);
        xCenter = parseFloat(center[0]);
        yCenter = parseFloat(center[1]);
        radius = parseDs9ArcLength(data[3], coordUnitSystem);
        toEllipse(xCenter, yCenter, parseFloat(abs(radius)),
                    parseFloat(abs(radius)), pa);
        
    /* ELLIPSE */
    } else if (indexOf(data[0], geometry[6]) == 0) {
        pa = parseDs9Angle(data[5]);
        center = parseDs9Coords(data[1], data[2], coordUnitSystem);
        xCenter = parseFloat(center[0]);
        yCenter = parseFloat(center[1]);
        /* For an ellipse the first axis in the code is the Yaxis.
            * Lets change the order to have Xaxis first and then Yaxis. */
        ax_y = parseDs9ArcLength(data[3], coordUnitSystem);
        ax_x = parseDs9ArcLength(data[4], coordUnitSystem);
        /* Set the major axis and convert the position angle if needed.
        In 'toEllipse' the position angle is that of the major axis, but
        in DS9 it is the angle of the X-axis. The position angle must
        be transformed to the angle of the biggest axis. Which is simply
        rotating it 90 degrees if the Y-axis is the major axis */
        if (abs(ax_x) > abs(ax_y)) {
            bmaj = ax_x;
            bmin = ax_y;
        } else {
            bmaj = ax_y;
            bmin = ax_x;
            pa = pa+PI/2;
        }
        toEllipse(xCenter, yCenter, parseFloat(abs(bmaj)), 
                    parseFloat(abs(bmin)), pa);
    } else {
        exit("Error: DS9 RoI type <" + data[0] + "> not recognized.");
    }
}


/**
 * Convert crtf angle to radians
 *
 * @param val  Input angle with units
 * @return  Converted angle in radians
 */
function parseCrtfAngle (val) {
    coordUnits = newArray("deg", "rad", "arcmin", "arcsec");
    for (j=0; j<coordUnits.length; j++) 
        if (indexOf(val, coordUnits[j]) != -1) unitsval=j; // read units
    angle = parseFloat(substring(val, 0, indexOf(val, coordUnits[unitsval])));
    if (unitsval == 0)  angle = angle*PI/180.0;
    else if (unitsval == 2) angle = (angle*PI/(180.0*60.0));
    else if (unitsval == 3) angle = (angle*PI/(180.0*3600.0));
    return angle;
}


/**
 * Convert ds9 angle to radians
 *
 * @param val  Input angle with units
 * @return  Converted angle in radians
 */
function parseDs9Angle (val) {
    coordUnits = newArray("deg", "rad", "\'", "\"");
    unitsFound = false;
    for (j=0; j<coordUnits.length; j++) {
        if (indexOf(val, coordUnits[j]) != -1) {
            unitsval=j; // read units
            unitsFound = true;
        }
    }
    if (unitsFound == true) {
        angle = parseFloat(substring(val, 0, indexOf(val, coordUnits[unitsval])));
        if (unitsval == 0)  angle = angle*PI/180.0;
        else if (unitsval == 2) angle = (angle*PI/(180.0*60.0));
        else if (unitsval == 3) angle = (angle*PI/(180.0*3600.0));
    } else {  // degrees when no symbol is present
        angle = parseFloat(val);
        angle = angle*PI/180.0;
    }
    return angle;
}


/**
 * Convert crtf coordinates to a FITS image pixel
 *
 * @param ra  RA with units
 * @param dec  DEC with units
 * @return  Pixel of the image containing input coordinates
 */
function parseCrtfCoords (ra, dec) {
    coordUnits = newArray ("deg", "rad", "pix");
    unitsval= 10;
    output = newArray(2);
    for (j=0; j<coordUnits.length; j++)
        if (indexOf(ra, coordUnits[j]) != -1) unitsval=j; // read units
    if (unitsval == 10) {   // Sexagesimal Coordinates
        // right ascension
        par = split(ra, "hdms:");
        if (par.length == 1 && indexOf(ra, ".") <= 5) {
            par = split(ra, ".");
            if (par.length > 3) par[2] = par[2] + "." + par[3];
        }
        rafin = (parseFloat(par[0]) + parseFloat(par[1])/60.0
                + parseFloat(par[2])/3600.0) * 15.0;
        // declination
        par = split(dec, "hdms:");
        if (par.length == 1 && indexOf(dec, ".") <= 5) {
            par = split(dec,".");
            if (par.length > 3) par[2] = par[2] + "." + par[3];
        }
        if (indexOf(dec, "-") != -1)
            decfin = parseFloat(par[0]) - parseFloat(par[1])/60.0
                     - parseFloat(par[2])/3600.0;
        else 
            decfin = parseFloat(par[0]) + parseFloat(par[1])/60.0
                     + parseFloat(par[2])/3600.0;

        output[0] = 
            call("CONVERT_PIXELS_COORDINATES.coord2FitsX", rafin, decfin, "");
        output[1] = 
            call("CONVERT_PIXELS_COORDINATES.coord2FitsY", rafin, decfin, "");
    } else {
        rafin = substring(ra, 0, indexOf(ra, coordUnits[unitsval]));
        decfin = substring(dec, 0, indexOf(dec, coordUnits[unitsval]));
        if (unitsval == 0 || unitsval == 1) {
            if (unitsval == 1) {
                rafin =  rafin*180.0/PI;
                decfin = decfin*180.0/PI;
            }
            output[0] = 
                call("CONVERT_PIXELS_COORDINATES.coord2FitsX", 
                     rafin, decfin, "");
            output[1] = 
                call("CONVERT_PIXELS_COORDINATES.coord2FitsY",
                     rafin, decfin, "");

        } else if ( unitsval == 2) {
            /* correction to change 0,0 starting point to 1,1 starting point
            of the FITS standard used in madcuba */
            corr = 1;
            output[0] = toString(parseFloat(rafin) + corr);
            output[1] = toString(parseFloat(decfin) + corr);
        }
    }
    return output;
}


/**
 * Convert ds9 coordinates to a FITS image pixel
 *
 * @param ra  RA with units
 * @param dec  DEC with units
 * @return  Pixel of the image containing input coordinates
 */
function parseDs9Coords (ra, dec, coordUnitSystem) {
    output = newArray(2);
    if (coordUnitSystem == "icrs") {
        output[0] = call("CONVERT_PIXELS_COORDINATES.coord2FitsX", ra, dec, "");
        output[1] = call("CONVERT_PIXELS_COORDINATES.coord2FitsY", ra, dec, "");

    } else if (coordUnitSystem == "image") {
        output[0] = toString(parseFloat(ra));
        output[1] = toString(parseFloat(dec));
    }
    return output;
}


/**
 * Convert crtf arcs in the sky to pixels
 * Note that this function uses the CDELT2 header parameter. This will
 * not be accurate for non-linear projections where CDELT1 != CDELT2.
 *
 * @param val  arc in the sky with units
 * @return  Converted arc
 */
function parseCrtfArcLength (val) {
    cdelt = parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    coordUnits = newArray("deg", "rad", "arcmin", "arcsec", "pix");
    unitsval = -1;
    coord = -1;

    for (j=0; j<coordUnits.length; j++)
        if (indexOf(val, coordUnits[j]) != -1) unitsval=j; // read units
    // case of request without units to use with polygon
    if (unitsval == -1) return coord;

    value = parseFloat(substring(val, 0, indexOf(val, coordUnits[unitsval])));
    if      (unitsval == 0) coord = value / cdelt;
    else if (unitsval == 1) coord = (value*180.0/PI) / cdelt;
    else if (unitsval == 2) coord = (value/60.0) / cdelt;
    else if (unitsval == 3) coord = (value/3600.0) / cdelt;
    else if (unitsval == 4) coord = value;
    return coord;
}


/**
 * Convert ds9 arcs in the sky to pixels
 * Note that this function uses the CDELT2 header parameter. This will
 * not be accurate for non-linear projections where CDELT1 != CDELT2.
 *
 * @param val  arc in the sky with units
 * @return  Converted arc
 */
function parseDs9ArcLength (val, coordUnitSystem) {
    cdelt = parseFloat(call("FITS_CARD.getDbl","CDELT2"));
    coordUnits = newArray("deg", "rad", "\'", "\"");
    unitsval = -1;
    coord = -1;
    if (coordUnitSystem == "icrs") {
        for (j=0; j<coordUnits.length; j++)
            if (indexOf(val, coordUnits[j]) != -1) unitsval=j; // read units
        if (unitsval == -1) value = parseFloat(val);
        else value = parseFloat(
            substring(val, 0, indexOf(val, coordUnits[unitsval])));
        if      (unitsval == 0) coord = value / cdelt;
        else if (unitsval == 1) coord = (value*180.0/PI) / cdelt;
        else if (unitsval == 2) coord = (value/60.0) / cdelt;
        else if (unitsval == 3) coord = (value/3600.0) / cdelt;
        else coord = value / cdelt;  // degrees when no symbol is present
    } else if (coordUnitSystem == "image") {
        value = parseFloat(val);
        coord = value;
    }
    return coord;
}


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
    // Returns four points in clockwise order starting from the top left.
    x1[0] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r1x));
    x1[1] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x + r2x));
    x1[2] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r1x));
    x1[3] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x - r2x));
    y1[0] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r1y));
    y1[1] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y + r2y));
    y1[2] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r1y));
    y1[3] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y - r2y));
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
function toEllipse(x, y, bmaj, bmin, pa) {
    x1 = x - bmaj*sin(pa);
    y1 = y + bmaj*cos(pa);
    x2 = x + bmaj*sin(pa);
    y2 = y - bmaj*cos(pa);
    e = bmin/bmaj;
    makeEllipse(x1, y1, x2, y2, e);
}