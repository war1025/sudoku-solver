

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
	}

	public class Row : Object {

		public void signal wrong();

		private Square[] squares;

		public Row(Square[] squares) {
			this.squares = new Square[9];
			for(int i = 0; i < squares.length; i++) {
				this.squares[i] = squares[i];
				this.squares[i].wrong.connect(() => {wrong();});
				this.squares[i].val_found.connect( (v) => {
						for(int j = 0; j < 9; j++) {
							squares[j].unsafe(v);
						}
					});
			}
		}


}
