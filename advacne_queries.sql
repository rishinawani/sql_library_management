--Task 9: Identify Members with Overdue Books
SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    -- rs.return_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1

/**Task 10: Update Book Status on Return**/
CREATE OR REPLACE Procedure add_return_records(p_return_id Varchar(10),p_issued_id Varchar(10)
) LANGUAGE plpgsql
AS $$
DECLARE
 v_isbn Varchar(50);
 v_book_name Varchar(80);
BEGIN
 INSERT INTO return_status(return_id, issued_id, return_date)
 VALUES
 (p_return_id, p_issued_id, Current_date);

 SELECT
   issued_book_isbn,
   issued_book_name
   INTO
   v_isbn,
   v_book_name
 FROM  issued_status
 WHERE issued_id = p_issued_id;

 UPDATE books
 SET status = 'yes'
 WHERE isbn = v_isbn;

 RAISE NOTICE 'Thankyou for returning the book: %', v_book_name;

 End;
 $$
SELECT * from return_status;
CALL add_return_records('RS138', 'IS135');

/**Task 11: Branch Performance Report**/
CREATE TABLE branch_reports
AS
SELECT 
    e.branch_id,
    b.branch_address,
    COUNT(DISTINCT i.issued_id) AS total_issued_books,
    COUNT(DISTINCT r.return_id) AS returned_books,
    SUM(bo.rental_price) AS total_revenue
FROM
    branch b
INNER JOIN 
    employees e ON b.branch_id = e.branch_id
INNER JOIN 
    issued_status i ON i.issued_emp_id = e.emp_id
LEFT JOIN 
    return_status r ON i.issued_id = r.issued_id
INNER JOIN 
    books bo ON i.issued_book_isbn = bo.isbn
GROUP BY 	
    e.branch_id,
    b.branch_address;
SELECT * FROM branch_reports;

/**Task 12: CTAS: Create a Table of Active Members**/
CREATE TABLE active_mem AS
SELECT 
    m.member_name,
    m.member_id,
    COUNT(*) AS issued_count
FROM 
    members m
INNER JOIN 
    issued_status i ON m.member_id = i.issued_member_id
WHERE 
    i.issued_date > CURRENT_DATE - INTERVAL '60 days'
GROUP BY 
    m.member_id, m.member_name;
SELECT * FROM active_mem;

--Task 13: Find Employees with the Most Book Issues Processed
SELECT 
 e.emp_name,b.*, count(i.issued_id)
 FROM employees e
 INNER JOIN branch b 
 ON e.branch_id = b.branch_id
 Inner Join issued_status i 
 ON e.emp_id = i.issued_emp_id
 GROUP BY 1,2
 order by count(i.issued_id) DESC
 LIMIT 3;

/** Task 14: Stored Procedure Objective: Create a stored procedure to manage the status **/
SELECT * FROM issued_status;
CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$
DECLARE
 v_status VARCHAR(10);
BEGIN
  SELECT status INTO
   v_status
  from books
  where  isbn = p_issued_book_isbn; 
  IF v_status = 'yes' THEN
   INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
   VALUES
   (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn , p_issued_emp_id);
   UPDATE books
    SET status = 'no'
   WHERE isbn = p_issued_book_isbn;
   RAISE NOTICE 'book records are added succesfully for book isbn: %', p_issued_book_isbn;
  ELSE
      RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
  END IF;
END;
$$
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');