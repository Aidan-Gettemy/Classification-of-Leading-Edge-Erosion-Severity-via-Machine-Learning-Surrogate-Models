function pitch = fix_init_bldptch(windspeed)
  y = readmatrix("bldptchpoints.txt");
  x = 3:26;
  if windspeed < 13
      pitch = 0;
  else
    pitch = spline(x,y,windspeed);
  end
end
