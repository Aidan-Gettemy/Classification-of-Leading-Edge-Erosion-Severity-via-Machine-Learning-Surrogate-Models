function rtspeed = fix_in_rt_speed(windspeed)
  y = readmatrix("rtpoints.txt");
  x = 3:26;
  if windspeed>11
      a = windspeed;
  else
      a = 13;
  end
  rtspeed = min(spline(x,y,windspeed),min(12.1,a));
end
