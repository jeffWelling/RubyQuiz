#!/usr/bin/ruby

class Array ; def random ; return nil if length.zero? ; entries[rand(length)] ; end ; end

class Cell
  
	def initialize walls=nil
		@walls= {}
		@neighbors= {}
    @walked_on=false
    @highlight=false
	end

	attr_reader :neighbors, :walls
  attr_accessor :contents

  def walked_on? ; @walked_on ; end

  def set_highlight state = true ; @highlight = state ; end
  def unset_highlight ; set_highlight false ; end
  def highlight? ; @highlight ; end

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
    return false unless neighbors[direction]
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
    neighbors.select {|dir,cell| self.passable?(dir) and !cell.walked_on? }
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

  def display options = {}
    wall      = options[:wall]      || '#'
    highlight = options[:highlight] || 'X'
    walked    = options[:walked]    || '.'
    open      = options[:open]      || ' '
    north_south_open = options[:north_south_open]
    east_west_open   = options[:east_west_open]

    if walls.member?(:north) && passable?(:north, false)
      if walked_on?
        north=walked
      else
        north=north_south_open || open
      end
    else
      north=wall
    end

    if walls.member?(:west) && passable?(:west, false)
      if walked_on?
        west=walked
      else
        west=east_west_open || open
      end
    else
      west=wall
    end

    if highlight?
      floor=highlight
    elsif contents
      floor=contents[0..0]
    elsif unvisited?
      floor=wall
    elsif walked_on?
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
  attr_reader :board, :length, :width, :highlighted_cell, :generated, :start_cell, :end_cell

	def initialize options = {}
    length, width = options[:length], options[:width]
		raise "length and width must be fixnums greater than zero" unless [length, width].all? {|n| n.respond_to?(:to_i) && !n.to_i.zero? }
    @length, @width = [length, width].collect {|n| n.to_i }
    setup_board options
  end

  def wipe_designations
    @highlighted_cell = @start_cell = @end_cell = @generated = @solved = nil
  end

  def setup_board options = {}
    wipe_designations
    circular = options[:circular]
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

  def set_highlight cell
    @highlighted_cell.unset_highlight if @highlighted_cell
    return if (@highlighted_cell = cell).nil?
    @highlighted_cell.set_highlight
  end

  def set_start_cell cell
    start_cell.contents = nil if start_cell
    return if (@start_cell = cell).nil?
    start_cell.contents = 'Start'
  end

  def set_end_cell cell
    end_cell.contents = nil if end_cell
    return if (@end_cell = cell).nil?
    end_cell.contents = 'End'
  end

  def random_cell
    cell = nil
    begin cell = board[rand(length)][rand(width)] end until cell
    cell
  end

  def generate options = {}
    watch = options[:watch]
    delay = options[:delay].to_f || 0.2
    return false if generated
    starting_cell = nil ; begin ; starting_cell = random_cell ; end while !starting_cell.unvisited?
    list = [ starting_cell ]
    begin
      cell = list.last
      begin ; print `clear` ; set_highlight cell ; display ; sleep delay ; end if watch
      unvisited = cell.unvisited_neighbors
      if unvisited.empty?
        list.pop
      else
        dir, other = unvisited.random
        cell.unset_wall dir 
        list << other
      end 
    end while !list.empty?
    set_highlight nil if watch
    @generated = true
  end 

  def stats
    return nil unless generated
    cells = board.flatten.compact
    num = cells.length
    branches = dead_ends = walked_on = unreachable = 0
    cells.each {|cell|
      exits = cell.walls.select {|d,state| !state }.length
      dead_ends += 1 if exits == 1
      branches += (exits - 2) if exits > 2
      walked_on += 1 if cell.walked_on?
      unreachable += 1 if cell.unvisited? || exits == 0 
    }
    [num, branches, dead_ends, (num / branches.to_f), walked_on, unreachable]
  end

  def solve options = {}
    watch = options[:watch]
    delay = options[:delay].to_f || 0.2
    starting_cell = random_cell
    crawl( starting_cell, 'not_walked_on_neighbors' ) {|cell, dir|
      cell.walk_on
      begin ; print `clear` ; set_highlight cell ; display ; sleep delay ; end if watch
    }
    set_highlight nil if watch
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
    wall_char = '#' ; pad = wall_char * (width * 2 + 1)
    fake = [[wall_char, wall_char], [wall_char, wall_char]]
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

  def solved?
    @solved ||= begin
      p [:solved?, highlighted_cell, end_cell]
      true if highlighted_cell && highlighted_cell == end_cell # only return and nil, so as not to cache a false
    end
  end

  def self.play maze = nil, options = {}
    options, maze = maze, nil if maze.is_a?(Hash)
    options[:length] ||= 11
    options[:width]  ||= 11
    maze = Maze.new options unless maze
    watch = options[:watch] || true
    delay = options[:delay] || 0.03

    command = nil
    result = nil
    loop do
      print `clear`
      if maze.generated && !maze.start_cell && !maze.end_cell
        maze.set_highlight(start = maze.random_cell)
        maze.set_start_cell start
        start.walk_on
        finish = nil ; begin ; finish = maze.random_cell ; end while finish == maze.highlighted_cell
        maze.set_end_cell finish
      end
      puts "Congratulations, you have naviagted the maze" if maze.solved?
      puts "Last command: #{command}" if command
      puts result if result
      result = nil
      maze.display
      puts "Command: "
      command = $stdin.gets.strip
      options = {:watch => watch, :delay => delay}
      case command
        when /^q/ ; break
        when /^w/ ; watch = !watch ; result = "Watch is #{watch}"
        when /^n/ ; maze.setup_board(:circular => false)
        when /^c/ ; maze.setup_board(:circular => true)
        when /^g/ ; maze.generate(options)
        when /^s/ ; maze.solve(options)
        when /^(\d+)\s?,\s?(\d+)$/ ; maze = Maze.new $1, $2, options
        when /^d(elay)?(=|\s?)([0-9.]+)/ ; delay = $3.to_f ; result = "Delay is #{delay}"
        when /^([ijkl])/
          next unless maze.highlighted_cell
          dirs = {'i' => :north, 'j' => :west, 'k' => :south, 'l' => :east}
          dir = dirs[$1]
          cell = maze.highlighted_cell
          new = cell.neighbors[dir] if cell.passable?(dir,false)
          maze.set_highlight new if new
          maze.highlighted_cell.walk_on unless maze.solved? # only store footprints while trying to solve the maze
      end
    end
    maze
  end

  def self.cli args
    options = {}
    args.each {|arg|
      next unless arg =~ /^-+([^=]*)(=(.*))?/ # key=val stored in $1 and $3
      args.delete arg                         # all non-numeric args are parsed and removed
      key, value = $1, $3
      case key
        when /^c(irc(le|ular)?)?$/ ; options[:circular] = true
        else ; puts "Unknown option #{arg} - parsed as #{key.inspect} = #{value.inspect}" ; exit
      end
    }
    options[:length], options[:width] = args.collect(&:to_i)
    play options
  end
end

if $0 == __FILE__
  Maze.cli ARGV
end
