class Cell
	def initialize walls=nil
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

	def set_west_wall
		@walls+=2 unless (@walls!=0 and @walls.even?)
	end

	def unset_west_wall
		@walls-=2 if (@walls!=0 and @walls.even?)
	end

  def add_reverse_neighbor original_direction, neighbor
    direction = {:east => :west, :west => :east, :north => :south, :south => :north}[original_direction]
    @neighbors[direction]=neighbor
  end
  protected :add_reverse_neighbor

	def add_neighbor direction, neighbor
		@neighbors[direction]=neighbor
    neighbor.add_reverse_neighbor direction, self
	end

	def del_neighbor direction
		@neighbors[direction]=nil
	end

	def dump
		[@neighbors,@walls]
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
		@board
	end
  attr_accessor :board
end
