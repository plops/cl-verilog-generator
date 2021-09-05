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
  ;; https://github.com/sipeed/Tang-Nano-examples/blob/master/example_led/led_prj/src/led.v
  (write-source (format nil "~a/source/01_test.v" *path*)
		`(module led
			 ("input sys_clk"
			  "input sys_rst_n"
			  "output reg [2:0] led")
			 "reg [23:0] counter;"
			 (always-at (or "posedge sys_clk"
					"negedge sys_rst_n")
				    (cond ((not sys_rst_n)
					   (assign<= counter "24'd0"))
					  ((< counter "24'd1200_0000")
					   (assign<= counter (+ counter 1)) ; (incf counter)
					   )
					  (t
					   (assign<= counter "24'd0"))
					  )
				  )
			 )
		))



 
