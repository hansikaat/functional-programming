defmodule Test do

  def stream() do
    t0 = :erlang.monotonic_time(:millisecond)
    ctrl = self()
    out = PPM.writer("invert.ppm", ctrl)
    out = Strm.start(gray_invert(), out)             
    out = Strm.start(gray_edge(), out)         
    out = Strm.start(gray_reduce(), out)     
    out = Strm.start(rgb_to_gray(), out)     
    PPM.reader("hockey.ppm", out)
    t1 = receive do
           :done ->
   	     :erlang.monotonic_time(:millisecond)	
         end 
    IO.puts("  total of  #{t1-t0} ms")        
  end


  def batch() do
    t0 = :erlang.monotonic_time(:millisecond)
    image = PPM.read("hockey.ppm")
    image = Batch.map(image, rgb_edge())
    PPM.write(image, "stream.ppm")
    t1 = :erlang.monotonic_time(:millisecond)
    IO.puts("  total of  #{t1-t0} ms")        
  end


  ## 1x1 kernels

  def rgb_to_gray() do
    fn({:rgb, size, depth}) ->
      {:ok, 1,
       {:gray, size, depth}, 
       fn({r,g,b}) ->
	 div(r+g+b, 3)
       end}
    end
  end

  def gray_reduce() do
    fn({:gray, size, 255}) ->
      {:ok, 1,
       {:gray, size, 3}, 
       fn(d) ->
	 div(d, 64)
       end}
    end
  end

  def gray_invert() do
    fn({:gray, size, depth}) ->
      {:ok, 1,
       {:gray, size, depth}, 
       fn(d) ->
           depth - d
       end}
    end
  end


  
  ## 3x3 kernels 

  def gray_edge() do
    fn ({:gray, size, depth}) ->
      {:ok, 3,
       {:gray, size, depth},
       fn(lines) -> Kern.fold([ 0, 1, 0,
  			        1,-4, 1,
			        0, 1, 0], lines, 0, depth) end}
    end
  end


  def rgb_edge() do
    fn ({:rgb, size, depth}) ->
      {:ok, 3,
       {:rgb, size, depth},
       fn(lines) -> Kern.fold([ 0, 1, 0,
  			        1,-4, 1,
			        0, 1, 0], lines, {0,0,0}, depth) end}
    end
  end



  
  def rgb_sharp() do
    fn ({:rgb, size, depth}) ->
      {:ok, 3,
       {:rgb, size, depth},
       fn(lines) -> Kern.fold([  0,-1, 0,
				-1, 5,-1,
			         0,-1, 0], lines, {0,0,0}, depth) end}
    end
  end  

  ## 5x5 kernels
  
  def rgb_blur() do
    fn ({:rgb, size, depth}) ->
      {:ok, 5,
       {:rgb, size, depth},       
       fn(lines) -> Kern.fold([ 0.04, 0.04, 0.04, 0.04, 0.04,
			        0.04, 0.04, 0.04, 0.04, 0.04,
			        0.04, 0.04, 0.04, 0.04, 0.04,
			        0.04, 0.04, 0.04, 0.04, 0.04,
			        0.04, 0.04, 0.04, 0.04, 0.04], lines, {0,0,0}, depth) end}
    end
  end
  

  
end

