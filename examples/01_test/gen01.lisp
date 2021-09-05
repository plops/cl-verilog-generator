(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload "cl-verilog-generator")
  (ql:quickload "alexandria"))

(in-package :cl-verilog-generator)

(progn
  (defparameter *path* "/home/martin/stage/cl-verilog-generator/examples/01_test")
  (defparameter *day-names*
    '("Monday" "Tuesday" "Wednesday"
      "Thursday" "Friday" "Saturday"
      "Sunday"))
  (write-source (format nil "~a/source/01_test.v" *path*)
					;`(paren 1 2 3)
		`(module led
			 "input sys_clk"
			 "input sys_rst_n"
			 "output reg led")
					;`(do0 (space module (led "input sys_clk")))
		))



