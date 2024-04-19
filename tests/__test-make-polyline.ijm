x = newArray(223.6,225,230.6);
y = newArray(212.4,216,215.4);
x2 = newArray(round(x.length));
y2 = newArray(round(y.length));
y_corr = 0;
x_corr = 0;
for (i=0; i<x.length; i++) {
    x2[i] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x[i])) + x_corr;
    y2[i] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y[i])) - y_corr;
}
//makeSelection("polygon", Xarray, Yarray);
// makeSelection("polygon", x2, y2);
makeSelection("polyline", x2, y2);
// makeLine(223,214,226,216,230,217);  // test con makeLine, sigue cogiendo pixel entero para saber que borrar
