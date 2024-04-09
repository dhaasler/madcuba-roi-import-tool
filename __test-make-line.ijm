// esta meterla a mano tambien despues
makeLine(20.3,16.3,22.4,18.6);

// al pichar en ella la macro recorder dice esto:
makeLine(20,16,23,19);
// que ya no selecciona lo mismo, pero si selecciona algunos pixeles de los que queriamos en codificacion porque sde contrarresta un poco

// pruebo a meter polyline con conversion hecha por plugin metido:
x1 = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", 20));
y1 = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", 16));
x2 = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", 23));
y2 = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", 19));
makeSelection("polyline", newArray(x1, x2), newArray(y1, y2));

// lo hago a mano como deberia ser de verdad
makeSelection("polyline", newArray(20-1, 23-1), newArray(90-(16-1), 90-(19-1)));
run("GET SPECTRUM", "roi");