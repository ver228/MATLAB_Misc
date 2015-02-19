FileName = '/Users/ver228/Downloads/movies_20141202/A003-20141202_165718.wmv';


A = mmread(FileName, [], [3600, 3601]);
imshow(A.frames(1).cdata)