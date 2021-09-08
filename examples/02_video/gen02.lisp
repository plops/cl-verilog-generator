(defpackage :cl-ov2640
  (:use :cl)
  )
(in-package :cl-ov2640)

;; register parser for ov2640 camera

(let
    ((l
       `((0 rsvd)
	 (5 r-bypass #x1 rw (((7 1) rsvd)
			     ((0) bypass-dsp-select ((0 dsp) (1 bypass)))))
	 (6 rsvd)
	 (44 qs #x0c rw quantization-scale-factor)))))
