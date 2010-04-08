

namespace Sudoku {

	public class Square : Object {

		public void signal val_found(int i);
		public void signal wrong();

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
			if(safe[i] && val < 0) {
				val = i;
				val_found(i);
			}
		}

		public void unsafe(int v) {
			if(val > 0) {
				return;
			}
			safe[v] = false;
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
						 val = i;
						 val_found(i);
					 }
				 }
			}
		}

		public int[] safe_vals() {
			int safe_count = 0;
			for(bool b in safe) {
				if(b) {
					safe_count++;
				}
			}
			int ret = new int[safe_count];
			int j = 0;
			for(int i = 0; i < ret.length; i++) {
				if(safe[i]) {
					ret[j++] = i;
				}
			}
			return ret;
		}
	}

	public class Row : Object {

		private Square[] squares;

		public Row(Square[] squares) {
			this.squares = new Square[9];
			for(int i = 0; i < squares.length; i++) {
				this.squares[i] = squares[i];
				this.squares[i].val_found.connect( (v) => {
						for(int j = 0; j < 9; j++) {
							this.squares[j].unsafe(v);
						}
					});
			}
		}
	}

	public class Board : Object {

		public void signal wrong();
		public void signal complete();

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
				rows[18 + i] = new Row(
						int s = ((i / 3) * 27) + (i % 3);
						new Square[] {	squares[s],
										squares[s + 1],
										squares[s + 2],
										squares[s + 9]
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

		public void set_val(int loc, int val) {
			squares[loc].set_val(val);
		}

		public int[] safe_vals(int loc) {
			return squares[loc].safe_vals();
		}

		public void min_safe(out int loc, out int[] safes) {
			safes = new int[10];
			int[] s = new int[10];
			for(int i = 0; i < 81; i++) {
				s = squares[i].safe_vals();
				if(s.length < safes.length) {
					loc = i;
					safes = s;
				}
			}
		}
	}
}
