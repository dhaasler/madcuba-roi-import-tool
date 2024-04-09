
x_fits = 18.1;   // starts at 1,1 on the bottom-left
y_fits = 18.1;
// makePoint(x_imagej, y_imagej);   // malo
makePoint(x_fits, y_fits);
// makePoint(x_imagej, y_imagej);    // pinta en mal sitio
// makePolygon(x_fits, y_fits);     // less than 3 points
run("GET SPECTRUM", "roi");