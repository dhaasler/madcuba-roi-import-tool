b = 1;
a = 0;
do {    
    print(b);     
    b++;
    a++;
    if (b==3 || a==1) stop=1;
} while (stop != 1)

// cuando es 2 entra por ultima vez, suma 1 y muestra 3. Como ya es 3, en la siguiente no entra