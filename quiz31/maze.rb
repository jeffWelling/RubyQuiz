
class Cell
	def initialize borders=nil, walls=nil
		@borders= ( borders.nil? ? 0 : borders )
		@walls= (walls.nil? ? 0 : walls)
	end

	def set_north_wall
		@walls+=1 unless @walls%2
	end

	def unset_north_wall
		@walls

	def set_north_boarder
		@borders+=1 unless @boardesr%2
	end

	def set_west_wall
		@walls+=2 unless @walls/2
	end

	def set_west_boarder
		@borders+=2 unless @borders/2
	end

	def dump
		[@borders,@walls]
	end

end
