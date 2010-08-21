#!/usr/bin/ruby

class Array ; def random ; return nil if length.zero? ; entries[rand(length)] ; end ; end

class Cell
  
	def initialize walls=nil
		@walls= {}
		@neighbors= {}
    @walked_on=false
	end

	attr_reader :neighbors, :walls, :walked_on

  def set_current
    p [:coy_old, @@currently_on]
    p [:coy_new, self]
    @@currently_on=self
  end

	def set_wall direction, state = true, both = true
    direction = direction.to_sym
    neighbors[direction].set_wall reverse_dir(direction), false, state if both
    @walls[direction] = state
	end

	def unset_wall direction, both = true
    set_wall direction, false, both
	end

  def passable? direction, both = false
    direction = direction.to_sym
    raise "No such neighbor - #{direction} from #{inspect}" unless @neighbors[direction]
    return false unless neighbors[direction].passable? reverse_dir(direction), false if both
    !@walls[direction] # if there isn't a wall, you're free to go
  end

  def reverse_dir direction
    direction = direction.to_sym
    @reverse_map ||= begin
      directions = [%w(east west), %w(north south), %w(up down), %w(in out)].collect {|a| a.collect &:to_sym }
      directions.inject({}) {|h,a| h[a.first] = a.last ; h[a.last] = a.first ; h }
    end
    @reverse_map[direction] || "reverse_of_#{direction}".to_sym
  end

	def add_neighbor direction, neighbor, reverse = false
    direction = direction.to_sym
    neighbor.add_neighbor direction, self, true unless reverse
    direction = reverse_dir(direction) if reverse
		@neighbors[direction] = neighbor
    @walls[direction]     = true
	end

	def del_neighbor direction, reverse = false
    direction = direction.to_sym
    if reverse
      direction = reverse_dir(direction)
    else
      raise "No such neighbor - #{direction} from #{inspect}" unless @neighbors[direction]
      @neighbors[direction].del_neighbor direction, true
    end
		[@neighbors, @walls].each {|h| h.delete direction }
	end

  def unvisited?
    walls.all? {|dir,wall| wall }
  end

  def unvisited_neighbors
    neighbors.select {|dir,cell| cell.unvisited? }
  end

  def not_walked_on_neighbors
    neighbors.select {|dir,cell| self.passable?(dir) and !cell.walked_on }
  end

	def dump
		[@neighbors,@walls]
	end

  def to_s
    "#{@neighbors.length} neighbors - #{@walls.inspect}"
  end

  def inspect
    "Cell(##{object_id.to_s(16)} #{to_s}"
  end

  def the_current_cell?
    begin @@currently_on rescue @@currently_on = nil end == self
  end

  def display options = {}
    wall    = options[:wall]    || '#'
    current = options[:current] || 'X'
    walked  = options[:walked]  || '.'
    open    = options[:open]    || ' '
    north_south_open = options[:north_south_open]
    east_west_open   = options[:east_west_open]

    if walls.member?(:north) && passable?(:north, false)
      if the_current_cell?
        north=current
      elsif walked_on==true
        north=walked
      else
        north=north_south_open || open
      end
    else
      north=wall
    end

    if walls.member?(:west) && passable?(:west, false)
      if the_current_cell?
        west=current
      elsif walked_on==true
        west=walked
      else
        west=east_west_open || open
      end
    else
      west=wall
    end

    if the_current_cell?
      floor=current
    elsif walked_on==true
      floor=walked
    else
      floor=open
    end

    [ [wall,   north],
      [west, floor] ]
  end

  def walk_on
    @walked_on=true
  end
end

class Maze
	def initialize length, width, options = {}
    circular = options[:circular]
    @length, @width = length, width
		raise "length and width must be fixnums" unless length.class==Fixnum and width.class==Fixnum

		@board=[[]]
		(0...length).each {|l|
			@board[l] ||=[]
			(0...width).each{|w|
        if circular
  				@board[l][w]=nil
          d = ((l - length / 2) ** 2 + (w - width / 2) ** 2)
          dim = [length, width].min / 2.to_f
          next unless d < ((    dim / 1) ** 2 - 2)
          next unless d > ((    dim / 3) ** 2 - 1)
        end
				@board[l][w]=cell=Cell.new
        oc = @board[l-1][w]
        oc.add_neighbor(:south, cell) unless l == 0 if oc
				oc = @board[l][w-1]
        oc.add_neighbor(:east,  cell) unless w == 0 if oc
			}
		}
		@board
	end

  def generate options = {}
    watch = options[:watch]
    delay = options[:delay].to_f || 0.2
    starting_cell = nil
    begin starting_cell = board[rand(length)][rand(width)] end until starting_cell
    list = [ starting_cell ]
    begin
      cell = list.last
      begin ; print `clear` ; cell.set_current ; display ; sleep delay ; end if watch
      unvisited = cell.unvisited_neighbors
      if unvisited.empty?
        list.pop
      else
        dir, other = unvisited.random
        cell.unset_wall dir 
        list << other
      end 
    end while !list.empty?
  end 

  def solve options = {}
    watch = options[:watch]
    delay = options[:delay].to_f || 0.2
    starting_cell = nil
    begin starting_cell = board[rand(length)][rand(width)] end until starting_cell
    crawl( starting_cell, 'not_walked_on_neighbors' ) {|cell, dir|
      cell.walk_on
      begin ; print `clear` ; cell.set_current ; display ; sleep delay ; end if watch
    }
  end 

  def crawl(starting_cell, get_neighbors)
    list = [ starting_cell ]
    begin
      cell=list.last
      neighbors= cell.send(get_neighbors.to_sym)
      if neighbors.empty?
        yield cell,nil
        list.pop
      else
        dir, other = neighbors.random
        yield cell, dir
        list << other
      end
    end while !list.empty?
  end

  def display
    fake = [['?','?'],['?','?']]
    wall_char = '#' ; pad = wall_char * (width * 2 + 1)
    board.each {|cells|
      rows = cells.inject([]) {|rows, cell|
        output = cell ? cell.display(:wall => wall_char) : fake
        output.each_with_index {|crow,i| (rows[i] ||= []) << crow }
        rows
      }
      rows = rows.collect {|row| "#{row.join}#{wall_char}" }
      puts rows.collect {|row| row }
    }
    puts pad
    nil
  end
  attr_reader :board, :length, :width

  def self.cli args
    circular = false
    args.each {|arg|
      next unless arg =~ /^-+([^=]*)(=(.*))?/ # key=val stored in $1 and $3
      args.delete arg                         # all non-numeric args are parsed and removed
      key, value = $1, $3
      case key
        when /^c(irc(le|ular)?)?$/ ; circular = true
        else ; puts "Unknown option #{arg} - parsed as #{key.inspect} = #{value.inspect}" ; exit
      end
    }
    len, wid = args.collect(&:to_i)
    maze = Maze.new len, wid, :circular => circular
    loop do
      maze.display
      puts "Command: "
      command = $stdin.gets.strip
      watch = true
      case command
        when /^w/ ; watch = !watch
        when /^n/ ; maze = Maze.new(len, wid, :circular => false)
        when /^c/ ; maze = Maze.new(len, wid, :circular => true)
        when /^g/ ; maze.generate(:watch => watch)
        when /^s/ ; maze.solve(:watch => watch)
        when /^q/ ; return
      end
    end
  end
end

if $0 == __FILE__
  Maze.cli ARGV
end
