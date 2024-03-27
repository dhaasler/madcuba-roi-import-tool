
x1 = 180;
y1 = 160;
r1 = 30;
r2 = 50;
x2 = x1 + (r2-r1);
y2 = y1 + (r2-r1);

// First method. Create a circular selection and subtract 
// from it by holding down alt key.
makeOval(x1, y1, r2*2, r2*2);
setKeyDown("alt");
makeOval(x2, y2, r1*2, r1*2);

// // Second method. Create a circular selection and add
// // to it using the Edit>Selection>Make Band command.
// width = r2 - r1;
// makeOval(x2, y2, r1*2, r1*2);
// run("Make Band...", "band="+width);
