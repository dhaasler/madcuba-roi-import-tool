x = newArray(223.2,225.01,230.4);
y = newArray(212.2,216,215.51);
x2 = newArray(round(x.length));
y2 = newArray(round(y.length));
y_corr = 0;
x_corr = 0;
for (i=0; i<x.length; i++) {
    x2[i] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x[i])) + x_corr;
    y2[i] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y[i])) - y_corr;
}

//makeSelection("polygon", Xarray, Yarray);
makeSelection("polygon", x2, y2);
// makePolygon(223,213,224,217,230,217);   // creates this polygon, this one is in fits coords