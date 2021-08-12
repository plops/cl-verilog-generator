(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload "cl-commonlisp-generator")
  (ql:quickload "alexandria"))
(in-package :cl-commonlisp-generator)



(progn
  (defparameter *path* "/home/martin/stage/cl-verilog-generator/")
  (defparameter *code-file* "v")
  (defparameter *source* (format nil "~a/" *path*))
  (defparameter *day-names*
    '("Monday" "Tuesday" "Wednesday"
      "Thursday" "Friday" "Saturday"
      "Sunday"))
  #+nil (defun lprint (cmd &optional rest)
    `(when debug
       (print (dot (string ,(format nil "{} ~a ~{~a={}~^ ~}" cmd rest))
		   (format (- (time.time) start_time)
			   ,@rest)))))
  (let* (
	 (code
	   `(toplevel
	     (in-package :cl-verilog-generator)
	     (setf
	       _code_git_version
	       (string ,(let ((str (with-output-to-string (s)
				     (sb-ext:run-program "/usr/bin/git" (list "rev-parse" "HEAD") :output s))))
			  (subseq str 0 (1- (length str)))))
	       _code_repository (string ,(format nil "https://github.com/plops/cl-verilog-generator/tree/master/gen-v.lisp"))
	       _code_generation_time
	       (string ,(multiple-value-bind
			      (second minute hour date month year day-of-week dst-p tz)
			    (get-decoded-time)
			  (declare (ignorable dst-p))
			  (format nil "~2,'0d:~2,'0d:~2,'0d of ~a, ~d-~2,'0d-~2,'0d (GMT~@d)"
				  hour
				  minute
				  second
				  (nth day-of-week *day-names*)
				  year
				  month
				  date
				  (- tz)))))
	     (setf (readtable-case *readtable*) :invert)
	     (toplevel
	      (defparameter *file-hashes* (make-hash-table))
	      (defun write-source (name code &key
					       (dir (user-homedir-pathname))
					       ignore-hash
					       (format t))
		(let* ((fn (merge-pathnames (format nil (string "~a") name)
					    dir))
		       (code-str (emit-v :code code))
		       (fn-hash (sxhash fn))
		       (code-hash (sxhash code-str)))
		  (multiple-value-bind (old-code-hash exists) (gethash fn-hash *file-hashes*)
		    (when (or (not exists) ignore-hash (/= code-hash old-code-hash)
			      (not (probe-file fn)))
		      ;; store the sxhash of the c source in the hash table
		      ;; *file-hashes* with the key formed by the sxhash of the full
		      ;; pathname
		      (setf (gethash fn-hash *file-hashes*) code-hash)
		      (with-open-file (s fn
					 :direction :output
					 :if-exists :supersede
					 :if-does-not-exist :create)
			(write-sequence code-str s))
		      (when format
			(sb-ext:run-program "/usr/local/bin/iStyle"
					    (list "--style=gnu"  (namestring fn)
						  ))))))))

	     (defun emit-v (&key
			      code
			      (level 0)
			      suffix)
	       (labels ((emit (code &key (dl 0) suffix)
			(emit-v :code code
				:level (+ dl level)
				:suffix suffix))
			(emits (code &key (dl 0) suffix)
			  (if (listp code)
			      (mapcar #'(lambda (x) (emit x
							 :dl dl
							 :suffix suffix))
				      code)
			      (emit code
				       :dl dl
				       :suffix suffix))))
		 (if code
		     (if (listp code)
			 (case (car code)
			   (comma (let ((args (cdr code)))
				    (format nil "~{~a~^, ~}" (emits args))))
			   (paren (let ((args (cdr code)))
				    (format nil "(~{~a~^, ~})" (emits args))))
			   (t (destructuring-bind (name &rest args) code
				(if (listp name)
				    "lambda call not supported"
				    (format nil "~a~a"
					    (emit name)
					    (emit `(paren ,@args)))))))
			 (cond
			   ((keywordp code)
			    (format nil "kw_~a" code))
			   ((symbolp code)
			    (format nil "~a" code))
			   ((stringp code)
			    (format nil "~a" code))
			   ((numberp code)
			    (cond
			      ((integerp code)
			       (format nil "~a" code))
			      (t
			       "float not supported")))))
		     "")))
	      
	     
	     
	     )))
    (write-source (format nil "~a/~a" *source* *code-file*) code)
    ))
