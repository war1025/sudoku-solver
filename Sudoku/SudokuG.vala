

namespace Sudoku {

	public class Square : Object {

		public signal void val_found(int i);

		private int val;

		private bool[] safe;

		public Square() {
			this.val = 0;
			this.safe = new bool[9];
			for(int i = 0; i < 9; i++) {
				safe[i] = true;
			}
		}

		public int get_val() {
			return val;
		}

		public void set_val(int v) {
			if(safe[v-1] && val <= 0) {
				val = v;
				for(int i = 1; i <= 9; i++) {
					unsafe(i);
				}
				val_found(v);
			}
		}

		public void unsafe(int v) {
			if(val == v) {
				return;
			}
			safe[v-1] = false;
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

		public bool is_safe(int v) {
			return safe[v-1];
		}
	}

	public class Row : Object {

		private Square[] squares;

		private bool[] needed;
		private int need_count;
		private int num_set;

		public Row(Square[] squares) {
			this.squares = new Square[9];

			for(int i = 0; i < squares.length; i++) {
				this.squares[i] = squares[i];
				this.squares[i].val_found.connect(found_update);
			}

			this.needed = new bool[9];
			for(int i = 0; i < 9; i++) {
				needed[i] = true;
			}

			need_count = 9;
			num_set = 0;
		}

		private void found_update(int i) {
			if(needed[i-1]) {
				need_count--;
			}
			needed[i-1] = false;
			num_set++;
		}

		public bool valid() {
			return (need_count + num_set) == 9;
		}

		public bool complete() {
			return (num_set == 9) && (need_count == 0);
		}

		public void update_safe() {
			for(int i = 0; i < 9; i++) {
				if(!needed[i]) {
					foreach (Square s in squares) {
						s.unsafe(i+1);
					}
				}
			}
		}

		public bool fill_vals() {
			bool did_something = false;
			for(int i = 0; i < 9; i++) {
				if(needed[i]) {
					int count = 0;
					foreach (Square s in squares) {
						if(s.is_safe(i+1)) {
							count++;
						}
					}
					if(count == 1) {
						did_something = true;
						foreach (Square s in squares) {
							s.set_val(i+1);
						}
					}
				}
			}
			return did_something;
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

		private Square[] squares;
		private Row[] rows;

		public Board() {
			squares = new Square[81];
			rows = new Row[27];

			for(int i = 0; i < 81; i++) {
				squares[i] = new Square();
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

		}

		public Board.copy(Board b) {
			this();
			for(int i = 0; i < 81; i++) {
				this.squares[i].set_val(b.squares[i].get_val());
			}
		}

		public void update_safe() {
			foreach (Row r in rows) {
				r.update_safe();
			}
		}

		public bool valid() {
			bool ret = true;
			foreach (Row r in rows) {
				ret &= r.valid();
			}
			return ret;
		}

		public bool complete() {
			bool ret = true;
			foreach (Row r in rows) {
				ret &= r.complete();
			}
			return ret;
		}

		public bool fill_vals() {
			bool did_something = false;
			foreach (Square s in squares) {
				int[] safe_vals = s.safe_vals();
				if(safe_vals.length == 1 && (s.get_val() == 0)) {
					did_something = true;
					s.set_val(safe_vals[0]);
				}
			}
			foreach (Row r in rows) {
				did_something |= r.fill_vals();
			}
			return did_something;
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
			for(int i = 9; i < 18; i++) {
				output.append("%s\n".printf(rows[i].to_string()));
			}
			return output.str;
		}
	}

	public class Sudoku : Object {

		private Board c_board;
		private bool solved;

		public Sudoku(int[] vals) {
			Board board = new Board();
			for(int i = 0; i < vals.length; i++) {
				if(vals[i] > 0) {
					board.set_val(i, vals[i]);
				}
			}
			active_solve(board);
		}

		private bool active_solve(Board b) {
			if(solve(b)) {
				return true;
			} else if(b.valid()){
				int[] safes;
				int loc;
				b.min_safe(out loc, out safes);
				foreach(int i in safes) {
					Board c = new Board.copy(b);
					if(active_solve(c)) {
						return true;
					}
				}
			}
			return false;
		}

		private bool solve(Board b) {
			bool go = true;
			while(go) {
				go = false;
				b.update_safe();
				go = b.fill_vals();
			}
			if(b.complete()) {
				c_board = b;
				solved = true;
				return true;
			} else {
				return false;
			}
		}


		public int[] get_vals() {
			return c_board.get_vals();
		}

		public string to_string() {
			if(solved) {
				return c_board.to_string();
			} else {
				return "No Solution Found";
			}
		}
	}

	public static void main(string[] args) {
		int[] vals = new int[81];
		string[] args2 = args[1].split(" ");
		for(int i = 0; i < 81; i++) {
			vals[i] = args2[i].to_int();
		}
		Sudoku s = new Sudoku(vals);
		stdout.printf("\n\n%s\n\n",s.to_string());
	}
}
