//            TM1 TM2 7m
// Fits X max 560,  , 90
// Fits Y max 560,  , 90

// cambiar ida y vuelta
x = 1;
y = 90;
print("X = " + x+ ", Y = ", y);
imagejx = call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x);
imagejy = call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y);
print("imageJX = " + imagejx + ", imageJY = ", imagejy);
height = call("FITS_CARD.getDbl","NAXIS2");
print("fits naxis2: " + height);
x2 = call("CONVERT_PIXELS_COORDINATES.imageJ2FitsX", imagejx);
y2 = call("CONVERT_PIXELS_COORDINATES.imageJ2FitsY", imagejy);
print("Recovered X = " + x2+ ", Recovered Y = ", y2);



// // poligono en fits
// // x = newArray(17.2,19.5,21.5);
// // y = newArray(18.3,22.5,20.5);
// x = newArray(17,19,19);
// y = newArray(18,19,17);

// x2 = newArray(round(x.length));
// y2 = newArray(round(y.length));
// for (i=0; i<x.length; i++) {
//     x2[i] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x[i]));
//     y2[i] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y[i]));
// }

// x3 = newArray(x[0]-0.5,x[1]-0.5,x[2]-0.5);                // ImageJ a mano (cantidad - 1)
// y3 = newArray(90-(y[0]-0.5),90-(y[1]-0.5),90-(y[2]-0.5));          // ImageJ a mano (ANCHO PIX - (cantidad - 1)).

// // makeSelection("polyline", x2, y2);

// // // makeSelection("polygon", Xarray, Yarray);
// makeSelection("polygon", x2, y2);               // transformed
// // makeSelection("polygon", x3, y3);               // a mano

// Array.show(x, y, x2, y2, x3, y3);