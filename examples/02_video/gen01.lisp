(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload "cl-verilog-generator")
  (ql:quickload "alexandria"))

(in-package :cl-verilog-generator)

(progn
  (defparameter *path* "/home/martin/stage/cl-verilog-generator/examples/02_video")
  (defparameter *day-names*
    '("Monday" "Tuesday" "Wednesday"
      "Thursday" "Friday" "Saturday"
      "Sunday"))
  ;; https://github.com/sipeed/TangNano-4K-example/blob/main/dk_video/project/src/ov2640/I2C_Interface.v
  ;; http://www4.cs.umanitoba.ca/~jacky/Teaching/Courses/74.795-LocalVision/ReadingList/ov-sccb.pdf
  (write-source (format nil "~a/source/i2c_interface.v" *path*)
		`(module i2c_interface
			 ("input clk"	;; 50MHz
			  "input siod"	;; SCCB data signal
			  "output sioc" ;; SCCB clock signal
			  "output taken" ;; flag to go to next address of LUT
			  "input send" ;; flag to indicate if configuration has finished
			  "input [7:0] rega" ;; register address
			  "input [7:0] value" ;; data to write into register address
			  )
			 ,@(loop for e in `((divider 7 "8'b00000001")
					    (busy_sr 31 "{32{1'b0}}")
					    (data_sr 31 "{32{1'b1}}")
					    (sioc_temp)
					    (taken_temp)
					    (siod_temp))
				 collect
				 (destructuring-bind (name &optional size default) e
				   (format nil "reg ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
			 ,@(loop for e in `(siod sioc taken)
				 collect
				 `(assign ,e ,(format nil "~a_temp" e)))
			 (always-at (or busy_sr (aref data_sr 31))
				    (if (logior
					 (== (aref busy_sr (slice 11 10))
					     "2'b10")
					 (== (aref busy_sr (slice 20 19))
					     "2'b10")
					 (== (aref busy_sr (slice 29 28))
					     "2'b10"))
					(setf siod_temp "1'bZ")
					(setf siod_temp (aref data_sr 31)))))))
