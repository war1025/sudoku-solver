

namespace Sudoku {

	/**
	 * A square keeps track of an individual cell of a sudoku board. It has a list of possible values,
	 * and a specific value (if known)
	 **/
	public class Square : Object {

		/**
		 * Emitted when the square's value is determined
		 **/
		public signal void val_found(int i);

		/**
		 * The actual value for the square
		 **/
		private int _val;

		/**
		 * The number of safe values for this square
		 **/
		public int safe_count {get; private set; default = 9;}

		/**
		 * An array of each possible value for the cell and whether that value could be used
		 **/
		private bool safe[9];

		/**
		 * Constructs an empty square with all values safe
		 **/
		public Square() {
			this.val = 0;
			for(int i = 0; i < 9; i++) {
				safe[i] = true;
			}
		}

		/**
		 * The value for the square.
		 *
		 * @get returns the value, or 0 if unset
		 * @set does nothing if already set,
		 * 		but sets the value, marks every other value unsafe, and emits the val_found signal
		 * 		when set for the first time.
		 **/
		public int val {
			get {
				return _val;
			}

			set {
				if(safe[value-1] && _val <= 0) {
					_val = value;
					for(int i = 1; i <= 9; i++) {
						unsafe(i);
					}
					val_found(value);
				}
			}
		}

		/**
		 * Marks the given value unsafe for this square,
		 * unless it is the value for this square.
		 *
		 * @param v The value that is unsafe
		 **/
		public void unsafe(int v) {
			if(val == v) {
				return;
			}
			if(safe[v-1]) {
				safe[v-1] = false;
				safe_count--;
			}
		}

		/**
		 * The set of values that it is safe for this square to take
		 *
		 * @return An array with the values this square can take
		 **/
		public int[] safe_vals() {
			// Create an array that is the correct size
			int[] ret = new int[safe_count];
			// Fill it with the safe values
			int j = 0;
			for(int i = 0; i < safe.length; i++) {
				if(safe[i]) {
					ret[j++] = i+1;
				}
			}
			return ret;
		}

		/**
		 * Whether the given value is safe for this square
		 *
		 * @param v The value
		 *
		 * @return Whether the value is safe
		 **/
		public bool is_safe(int v) {
			return safe[v-1];
		}
	}

	/**
	 * A row is a set of 9 squares. The values 1 - 9 must occur in a row.
	 * Row is used for both the horizontal and vertical row, as well as the 9-square
	 **/
	public class Row : Object {

		/**
		 * The squares for the row
		 **/
		private Square squares[9];

		/**
		 * Which values are needed and not needed
		 **/
		private bool needed[9];

		/**
		 * How many values are still needed for this row
		 **/
		private int need_count;

		/**
		 * How many values have been set in this row
		 **/
		private int num_set;

		/**
		 * Constructs a row out of the given squares
		 *
		 * @param squares The nine squares that make up this row
		 **/
		public Row(Square[] squares) {
			// Add the squares and connect to their val_found signal
			for(int i = 0; i < squares.length; i++) {
				this.squares[i] = squares[i];
				this.squares[i].val_found.connect(found_update);
			}

			// We still need to find all the values for this row
			for(int i = 0; i < 9; i++) {
				needed[i] = true;
			}

			need_count = 9;
			num_set = 0;
		}

		/**
		 * Connected to the squares' val_found signal.
		 * Marks values as found as we find them, and tracks how many
		 * have been found / set.
		 *
		 * @param i The value that was found
		 **/
		private void found_update(int i) {
			if(needed[i-1]) {
				need_count--;
			}
			needed[i-1] = false;
			num_set++;
		}

		/**
		 * Whether this row is in a valid state
		 *
		 * @return validity of this row
		 **/
		public bool valid() {
			// Valid if the sum of squares that have found values
			// and the number of values that are still needed is 9.
			// If two squares have been given the same value, this number will be wrong.
			return (need_count + num_set) == 9;
		}

		/**
		 * Whether this row is complete and valid
		 *
		 * @return The completeness of this row
		 **/
		public bool complete() {
			// If all squares are set and we don't need any more values then we've
			// completed this row.
			return (num_set == 9) && (need_count == 0);
		}

		/**
		 * Updates the safe values for this row.
		 * Any value that is already found in this row is
		 * unsafe for any other square in the row.
		 **/
		public void update_safe() {
			// For each value 1 - 9
			for(int i = 0; i < 9; i++) {
				// If a square in the row already has that value
				if(!needed[i]) {
					// Tell each square in the row that that value is unsafe
					foreach (Square s in squares) {
						s.unsafe(i+1);
					}
				}
			}
		}

		/**
		 * Attempt to fill in values for this row.
		 * Fills any squares that have only one safe value.
		 *
		 * @return Whether any values were found.
		 **/
		public bool fill_vals() {
			bool did_something = false;
			// For each value 1 - 9
			for(int i = 0; i < 9; i++) {
				// If we still need it
				if(needed[i]) {
					// Try to find a unique place for it to go.
					int count = 0;
					int pos = 0;
					for(int j = 0; j < squares.length; j++) {
						if(squares[j].is_safe(i+1)) {
							count++;
							pos = j;
						}
					}
					if(count == 1) {
						did_something = true;
						squares[pos].val = i + 1;
					}
				}
			}
			// Return whether we set at least one value
			return did_something;
		}

		/**
		 * The row as a string
		 *
		 * @return String version of the row
		 **/
		public string to_string() {
			StringBuilder sb = new StringBuilder();
			sb.append(" | ");
			for(int i = 0; i < 9; i++) {
				int val = squares[i].val;
				sb.append("%d ".printf(val));
				if(i % 3 == 2) {
					sb.append("| ");
				}
			}
			return sb.str;
		}
	}

	/**
	 * A board represents a standard sudoku board.
	 **/
	public class Board : Object {

		/**
		 * The squares on the board
		 **/
		private Square squares[81];

		/**
		 * The rows on the board, with the 9-squares being counted as rows
		 **/
		private Row rows[27];

		/**
		 * Constructs a board, linking together the squares and rows properly
		 **/
		public Board() {
			// Create the squares
			for(int i = 0; i < 81; i++) {
				squares[i] = new Square();
			}

			// Vertical rows
			for(int i = 0; i < 9; i++) {
				rows[i] = new Row(
						new Square[]{	squares[i],
										squares[i + 9],
										squares[i + 18],
										squares[i + 27],
										squares[i + 36],
										squares[i + 45],
										squares[i + 54],
										squares[i + 63],
										squares[i + 72]
									  });
			}

			// Horizontal rows
			for(int i = 0; i < 9; i++) {
				int row_offset = 9 * i;
				rows[9 + i] = new Row(
						new Square[] {	squares[row_offset],
										squares[row_offset + 1],
										squares[row_offset + 2],
										squares[row_offset + 3],
										squares[row_offset + 4],
										squares[row_offset + 5],
										squares[row_offset + 6],
										squares[row_offset + 7],
										squares[row_offset + 8]
									 });
			}

			// 9-squares
			for(int i = 0; i < 9; i++) {
				int s = ((i / 3) * 27) + ((i % 3)*3);
				rows[18 + i] = new Row(
						new Square[] {	squares[s],
										squares[s + 1],
										squares[s + 2],
										squares[s + 9],
										squares[s + 10],
										squares[s + 11],
										squares[s + 18],
										squares[s + 19],
										squares[s + 20]
									 });
			}

		}

		/**
		 * Copy constructor
		 *
		 * @param b The board to copy
		 **/
		public Board.copy(Board b) {
			this();
			for(int i = 0; i < 81; i++) {
				int val = b.squares[i].val;
				if(val > 0) {
					this.squares[i].val = val;
				}
			}
		}

		/**
		 * Update safe values for squares in the board
		 **/
		public void update_safe() {
			// No new values will be set by this operation,
			// So just loop through all the rows and update_safe() for them
			foreach (Row r in rows) {
				r.update_safe();
			}
		}

		/**
		 * Whether the board is in a valid state.
		 * The board is valid as long as a row does not contain duplicate entries
		 *
		 * @param The validity of this board
		 **/
		public bool valid() {
			bool ret = true;
			foreach (Row r in rows) {
				ret &= r.valid();
			}
			return ret;
		}

		/**
		 * Whether the board is in a complete and valid state.
		 * This means that the board has been solved
		 *
		 * @param Whether the board is complete / solved
		 **/
		public bool complete() {
			bool ret = true;
			foreach (Row r in rows) {
				ret &= r.complete();
			}
			return ret;
		}

		/**
		 * Try to fill in values on the board.
		 * Do this by first checking each individual square to see
		 * if it has only one possible value, and set those squares
		 * Then try to fill in values based on there being only one valid place for a value
		 * in a given row
		 *
		 * @return Whether at least one new value was found
		 **/
		public bool fill_vals() {
			bool did_something = false;
			// Check all the squares and see if they can be set directly
			foreach (Square s in squares) {
				if((s.safe_count == 1) && (s.val == 0)) {
					did_something = true;
					s.val = s.safe_vals()[0];
				}
			}
			// Then check all the rows and try to set values that way
			foreach (Row r in rows) {
				did_something |= r.fill_vals();
			}
			// Whether we found at least one value
			return did_something;
		}

		/**
		 * Set the value for a given square
		 *
		 * @param loc The index of the square
		 * @param val The value the square at that index should take
		 **/
		public void set_val(int loc, int val) {
			squares[loc].val = val;
		}

		/**
		 * Gets the set of safe values for the square at a given location
		 *
		 * @param loc The index of the square in question
		 *
		 * @return The values that are safe at that square
		 **/
		public int[] safe_vals(int loc) {
			return squares[loc].safe_vals();
		}

		/**
		 * Find a square with the smallest number of safe values on the board.
		 *
		 * @param out loc The location of the square, or -1 if the board is complete
		 * @param out safes The safe values for that location, or null if the board is complete
		 **/
		public void min_safe(out int loc, out int[] safes) {
			loc = -1;
			safes = null;
			int safe_length = 10;
			for(int i = 0; i < 81; i++) {
				if((squares[i].val <= 0) && (squares[i].safe_count < safe_length)) {
					loc = i;
					safes = squares[i].safe_vals();
					safe_length = safes.length;
				}
			}
		}

		/**
		 * Get all the values for the board in its current state, with 0 being unset
		 *
		 * @return An array of all the current values for the board in row order
		 **/
		public int[] get_vals() {
			int[] ret = new int[81];
			for(int i = 0; i < 81; i++) {
				ret[i] = squares[i].val;
			}
			return ret;
		}

		/**
		 * A string representation of the board
		 *
		 * @return The board as a string
		 **/
		public string to_string() {
			StringBuilder output = new StringBuilder();
			output.append(" -------------------------\n");
			for(int i = 9; i < 18; i++) {
				output.append("%s\n".printf(rows[i].to_string()));
				if(i % 3 == 2) {
					output.append(" -------------------------\n");
				}
			}
			return output.str;
		}
	}

	/**
	 * The sudoku class solves a given sudoku puzzle
	 **/
	public class Sudoku : Object {

		/**
		 * The board for this sudoku
		 **/
		private Board c_board;

		/**
		 * Whether this sudoku is solved
		 **/
		private bool solved;

		/**
		 * Constructs a sudoku board with the given values, then attempts to solve it.
		 *
		 * @param vals The values in row order for the board, with 0 being unset.
		 **/
		public Sudoku(int[] vals) {
			Board board = new Board();
			for(int i = 0; i < vals.length; i++) {
				if(vals[i] > 0) {
					board.set_val(i, vals[i]);
				}
			}
			active_solve(board);
		}

		/**
		 * Attempts to solve the sudoku board by guessing if needed
		 *
		 * @param b The board to solve
		 *
		 * @return Whether the board is solved
		 **/
		private bool active_solve(Board b) {
			// Attempt to solve passively
			if(solve(b)) {
				return true;
			// Otherwise, if the board is still in a valid state
			// Get the square that has the smallest number of possible values,
			// And try each value.
			} else if(b.valid()){
				int[] safes;
				int loc;
				b.min_safe(out loc, out safes);
				foreach(int i in safes) {
					// Recursively attempt to solve by creating a copy of the board
					// with one of the possible values for the square, and try to solve that board.
					Board c = new Board.copy(b);
					c.set_val(loc,i);
					if(active_solve(c)) {
						return true;
					}
				}
			}
			// Could not solve the board. No solution.
			return false;
		}

		/**
		 * Attempt to solve the board using only logic, no guessing.
		 *
		 * @param b The board to solve
		 *
		 * @return Whether the board was solved
		 **/
		private bool solve(Board b) {
			// Iteratively attempt to fill in values
			// Until we cannot fill in any more values
			bool go = true;
			while(go && b.valid()) {
				go = false;
				b.update_safe();
				go = b.fill_vals();
			}
			// If the board is solved successfully, mark as solved
			if(b.complete()) {
				c_board = b;
				solved = true;
				return true;
			// Otherwise indicate that the board isn't solved
			} else {
				return false;
			}
		}

		/**
		 * Get the values of the solved sudoku
		 *
		 * @return The values for the sudoku in row order
		 **/
		public int[] get_vals() {
			return c_board.get_vals();
		}

		/**
		 * The sudoku as a string
		 *
		 * @return String for the sudoku board
		 **/
		public string to_string() {
			if(solved) {
				return c_board.to_string();
			} else {
				return "No Solution Found";
			}
		}
	}

	/**
	 * Read in a board from the args, solve and print.
	 **/
	public static void main(string[] args) {
		int vals[81];
		string[] args2 = args[1].strip().split_set("\n ");
		for(int i = 0; i < 81; i++) {
			vals[i] = int.parse(args2[i]);
		}
		Sudoku s = new Sudoku(vals);
		stdout.printf("\n\n%s\n\n",s.to_string());
	}
}
