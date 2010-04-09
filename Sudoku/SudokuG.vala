

namespace Sudoku {

	public class Square : Object {

		public signal void val_found(int i);
		public signal void wrong();

		private int val;

		private bool[] safe;

		public Square() {
			this.val = -1;
			this.safe = new bool[9];
			for(int i = 0; i < 9; i++) {
				safe[i] = true;
			}
		}

		public int get_val() {
			return val;
		}

		public void set_val(int i) {
			if(safe[i-1] && val < 0) {
				val = i;
				val_found(i);
			}
		}

		public void unsafe(int v) {
			if(val > 0) {
				return;
			}
			safe[v-1] = false;
			int safe_count = 0;
			for(int i = 0; i < 9; i++) {
				if(safe[i]) {
					safe_count++;
				}
			}
			if(safe_count == 0) {
				wrong();
			} else if(val < 0 && safe_count == 1) {
				 for(int i = 0; i < 9; i++) {
					 if(safe[i]) {
						 val = i+1;
						 val_found(i+1);
					 }
				 }
			}
		}

		public int[] safe_vals() {
			int safe_count = 0;
			foreach (bool b in safe) {
				if(b) {
					safe_count++;
				}
			}
			int[] ret = new int[safe_count];
			int j = 0;
			for(int i = 0; i < ret.length; i++) {
				if(safe[i]) {
					ret[j++] = i+1;
				}
			}
			return ret;
		}
	}

	public class Row : Object {

		public signal void wrong();

		private Square[] squares;

		public Row(Square[] squares) {
			this.squares = new Square[9];
			for(int i = 0; i < squares.length; i++) {
				this.squares[i] = squares[i];
				this.squares[i].val_found.connect( (v) => {
						for(int j = 0; j < 9; j++) {
							this.squares[j].unsafe(v);
						}
						int count = 0;
						foreach (Square s in this.squares) {
							if(s.get_val() == v) {
								count++;
							}
						}
						if(count > 1) {
							wrong();
						}
					});
			}
		}

		public string to_string() {
			StringBuilder sb = new StringBuilder();
			foreach (Square s in squares) {
				int val = s.get_val();
				sb.append("%d ".printf((val > 0) ? val : 0));
			}
			return sb.str;
		}
	}

	public class Board : Object {

		public signal void wrong();
		public signal void complete();

		private Square[] squares;
		private Row[] rows;
		private int squares_left;

		public Board() {
			squares = new Square[81];
			rows = new Row[27];

			squares_left = 81;

			for(int i = 0; i < 81; i++) {
				squares[i] = new Square();
				squares[i].wrong.connect( () => {wrong();});
				squares[i].val_found.connect( () => {
						squares_left--;
						if(squares_left <= 0) {
							complete();
						}
					});
			}

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

			for(int i = 0; i < 9; i++) {
				rows[9 + i] = new Row(
						new Square[] {	squares[9*i],
										squares[9*i + 1],
										squares[9*i + 2],
										squares[9*i + 3],
										squares[9*i + 4],
										squares[9*i + 5],
										squares[9*i + 6],
										squares[9*i + 7],
										squares[9*i + 8]
									 });
			}

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

			foreach (Row r in rows) {
				r.wrong.connect( () => {wrong();});
			}

		}

		public Board.copy(Board b) {
			this();
			for(int i = 0; i < 81; i++) {
				this.squares[i].set_val(b.squares[i].get_val());
			}
		}

		public void set_val(int loc, int val) {
			squares[loc].set_val(val);
		}

		public int[] safe_vals(int loc) {
			return squares[loc].safe_vals();
		}

		public void min_safe(out int loc, out int[] safes) {
			safes = new int[10];
			loc = -1;
			int[] s = new int[10];
			for(int i = 0; i < 81; i++) {
				s = squares[i].safe_vals();
				if((squares[i].get_val() < 0) && (s.length < safes.length)) {
					loc = i;
					safes = s;
				}
			}
			int[] copy = new int[safes.length];
			for(int i = 0; i < safes.length; i++) {
				copy[i] = safes[i];
			}
			safes = copy;
debug("Min Safe Loc: %d",loc);
		}

		public int[] get_vals() {
			int[] ret = new int[81];
			for(int i = 0; i < 81; i++) {
				ret[i] = squares[i].get_val();
			}
			return ret;
		}

		public string to_string() {
			StringBuilder output = new StringBuilder();
			int count = 0;
			foreach(Row r in rows) {
				if(count % 9 == 0) {
					output.append("\n\n\n");
				}
				count++;
				output.append("%s\n".printf(r.to_string()));
			}
			return output.str;
		}
	}

	public class Sudoku : Object {

		private Board c_board;
		private bool complete;

		public Sudoku(int[] vals) {
			Board board = new Board();
			complete = false;
			board.complete.connect( () => {debug("Board Complete, %s", board.to_string()); this.c_board = board; debug("A"); this.complete = true; debug("B");});
			for(int i = 0; i < vals.length; i++) {
				if(vals[i] > 0) {
					board.set_val(i, vals[i]);
				}
			}
			if(!complete) {
				solve(board);
			}
		}

		public void solve(Board b) {
			bool invalid = false;
			int[] safes;
			int loc;
			b.min_safe(out loc, out safes);
			if(loc >= 0) {
				foreach (int i in safes) {
					invalid = false;
					Board c = new Board.copy(b);
					c.wrong.connect( () => {invalid = true;});
					c.complete.connect( () => {if(!invalid) {c_board = c; complete = true;}});
					c.set_val(loc, i);
					if(complete) {
						return;
					}

					if(!invalid) {

						solve(c);

					}

					if(complete) {

						return;
					}
				}
			}
			debug("Out of ideas");
		}

		public int[] get_vals() {
debug("Complete: %s", complete.to_string());
			return c_board.get_vals();
		}
	}

	public static void main(string[] args) {
		int[] vals = new int[81];
		string[] args2 = args[1].split(" ");
		for(int i = 0; i < 81; i++) {
			vals[i] = args2[i].to_int();
		}
		Sudoku s = new Sudoku(vals);
		int[] ret = s.get_vals();
		for(int i = 0; i < 9; i++) {
			for(int j = 0; j < 9; j++) {
				stdout.printf("%d ",ret[9*i + j]);
			}
			stdout.printf("\n");
		}
	}
}
