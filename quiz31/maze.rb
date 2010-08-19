class Cell
	def initialize borders=nil, walls=nil
		@borders= ( borders.nil? ? 0 : borders )
		@walls= (walls.nil? ? 3 : walls)
		@neighbors={:north=>nil, :east=>nil, :south=>nil, :west=>nil}
	end

	attr_accessor :neighbors

	def set_north_wall
		@walls+=1 unless @walls.odd?
	end

	def unset_north_wall
		@walls-=1 if @walls.odd?
	end

	def set_north_border
		@borders+=1 unless @borders.odd?
	end

	def unset_north_border
		@borders-=1 if @borders.odd?
	end

	def set_west_wall
		@walls+=2 unless (@walls!=0 and @walls.even?)
	end

	def unset_west_wall
		@walls-=2 if (@walls!=0 and @walls.even?)
	end

	def set_west_border
		@borders+=2 unless (@borders != 0 and @borders.even?)
	end

	def unset_west_border
		@borders-=2 if (@borders!=0 and @borders.even?)
	end
	
	def add_neighbor direction, neighbor
		@neighbors[direction]=neighbor
	end

	def del_neighbor direction
		@neighbors[direction]=nil
	end

	def dump
		[@borders,@walls]
	end

end

class Maze
	def initialize length, width
		raise "length and width must be fixnums" unless length.class==Fixnum and width.class==Fixnum

		first_cell=nil
		@board=[[]]
		(0...length).each {|l|
			@board[l] ||=[]
			(0...width).each{|w|
				@board[l][w]=cell=Cell.new
        @board[l-1][w].add_neighbor(:south, cell) unless l == 0
				@board[l][w-1].add_neighbor(:east,  cell) unless w == 0
			}
		}
    set_borders
		@board
	end
  attr_accessor :board
  
  def set_borders
    (0..board.length-1).each do |l| board[l][0].set_west_border end
    (0..board[0].length-1).each do |w| board[0][w].set_north_border end
  end
end
