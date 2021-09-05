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
	     "(in-package :cl-verilog-generator)"
	     (defparameter
		 _code_git_version
	       (string ,(let ((str (with-output-to-string (s)
				     (sb-ext:run-program "/usr/bin/git" (list "rev-parse" "HEAD") :output s))))
			  (subseq str 0 (1- (length str)))))
	       
	       )
	     (defparameter _code_generation_time
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
	     (defparameter
		 _code_repository (string ,(format nil "https://github.com/plops/cl-verilog-generator/tree/master/gen-v.lisp")))
	     
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
			("sb-ext:run-program" (string "/usr/bin/iStyle")
					    (list (string "--style=gnu")  (namestring fn)
						  ))))))))

	     (defun emit-v (&key
			      code
			      (level 0)
			      suffix)
	       (labels ((emit (code &key (dl 0) ; suffix
				      )
			(emit-v :code code
				:level (+ dl level)
				:suffix suffix))
			(emits (code &key (dl 0) ;suffix
				       )
			  (if (listp code)
			      (mapcar #'(lambda (x) (emit x
							 :dl dl
							; :suffix suffix
							 ))
				      code)
			      (emit code
				       :dl dl
				       ;:suffix suffix
				       ))))
		 (if code
		     (if (listp code)
			 ,(flet ((row (body)
				   `(destructuring-bind (name &rest args) code
				      (with-output-to-string (s)
					(macrolet ((out (cmd &rest rest)
						     "`(format s ,cmd ,@rest)")
						   (outsemiln (cmd &rest rest)
						     "`(format s
							      (concatenate 'string
									   ,cmd
									   (format nil
										   \";~@[ // ~a~]~%\"
										   suffix))
							      ,@rest)"
						     )
						   (outln (cmd &rest rest)
						     "`(format s
							      (concatenate 'string
									   ,cmd
									   (format nil
										   \" // ~a~%\"
										   suffix))
							      ,@rest)"
						     ))
					  
					  
					  ,body)))))
			    `(case (car code)
			       (comment
				,(row
				  `(setf suffix (first args))))
			       (comma
				#+nil
				(format nil (string "~{~a~^, ~}") (emits (cdr code))
					;(mapcar #'emit (cdr code))
					)
				,(row `(out (string "~{~a~^, ~}") (emits args))))
			       (paren
				,(row `(out (string "(~{~a~^, ~})") (emits args))))
			       (concat
				,(row `(out (string "{~{~a~^, ~}}") (emits args))))
			       (space
				,(row `(out (string "~{~a~^, ~}") (emits args))))
			       (module
				,(row `(destructuring-bind (name params &rest body) args
					 (outsemiln (string "module ~a ~a")
						     (emit name)
						     (emit "`(paren ,@params)"))
					 (loop for b in body
					       do
					       (outln (string "~a") (emit b)))
					 (outln (string "endmodule")))))
			       (always-at
				,(row `(destructuring-bind (condition &rest body) args
					 (outsemiln (string "always @~a begin")
						    (emit "`(paren ,condition)"))
					 (loop for b in body
					       do
					       (outln (string "~a") (emit b)))
					 (outln (string "end")))))
			       ,@(loop for op in `(or +) ;; operators with arbitrary number of arguments
				       collect
				       `(,op
					 ,(row `(out (string ,(format nil "~~{(~~a)~~^ ~a ~~}" op))
						     (emits args)))))
			       ,@(loop for op in `(< <= ==) ;; operators with two arguments
				       collect
				       `(,op
					 ,(row `(out (string ,(format nil "((~~a) ~a (~~a))" op))
						     (emit (first args))
						     (emit (second args))))))
			       
			       #+nil(<.
				,(row `(out (string "((~a)<(~a))")
					    (emit (first args))
					    (emit (second args)))))
			       #+nil (<=
				,(row `(out (string "((~a)<=(~a))")
					    (emit (first args))
					    (emit (second args)))))
			       (assign<=
				,(row `(outsemiln (string "~a <= ~a")
						  (emit (first args))
						  (emit (second args)))))
			       (setf
				,(row
				  `(loop for (a b) on args by #'cddr
					 collect
					 (out (string "~a") (emit "`(assign<= ,a ,b)")))
				  ))
			       (incf
				,(row
				  `(destructuring-bind (target &optional (increment 1)) args
				     (out (string "~a")
					  (emit "`(setf ,target (+ ,target ,increment))")))
				  ))
			       (not
				,(row `(out (string "(! (~a))")
					    (emit (elt args 0)))))
			       (aref ,(row
				       `(destructuring-bind (name &rest indices) args
					  (out (string "~a[~{~a~^,~}]")
					       (emit name)
					       (emits indices)))))
			       (slice
				,(row
				  `(out (string "~a:~a")
					(emit (first args))
					(emit (second args))))
				)
			       (cond
				 ,(row `(loop for clause in args
					      and ci from 0
					      collect
					      (destructuring-bind (condition &rest body) clause
						  (if (eq ci 0)
						      (outln (string "if ~a")
							     (emit condition))
						      (if (eq condition t)
							  (outln (string "else ")
								 )
							  (outln (string "else if ~a")
								 (emit condition))))
						(loop for b in body
						      do
							 (outln (string "~a") (emit b))))
					      )
				       )
				 )
			       (do0
				,(row `(out (string "~{~a~^~%~}") (emits args))))
			       (t ,(row `(if (listp name)
					     (string "lambda call not supported")
					     (out (string "~a~a")
						  (emit name)
						  (emit "`(paren ,@args)"))))
				)))
			 (cond
			   ((keywordp code)
			    (format nil (string "kw_~a") code))
			   ((symbolp code)
			    (format nil (string "~a") code))
			   ((stringp code)
			    (format nil (string "~a") code))
			   ((numberp code)
			    (cond
			      ((integerp code)
			       (format nil (string "~a") code))
			      (t
			       (string "float not supported"))))))
		     (string ""))))
	      
	     
	     
	     )))
    (cl-commonlisp-generator:write-source
     (format nil "~a/~a" *source* *code-file*)
     code)))
