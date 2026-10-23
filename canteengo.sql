INSERT INTO MENU_ITEMS VALUES (101, 'Masala Chai', 4, 15, 'Y');
INSERT INTO MENU_ITEMS VALUES (102, 'Cold Coffee', 4, 50, 'Y');
INSERT INTO MENU_ITEMS VALUES (103, 'Fresh Lime Soda', 4, 30, 'Y');
INSERT INTO MENU_ITEMS VALUES (104, 'Lassi', 4, 40, 'Y');
INSERT INTO MENU_ITEMS VALUES (105, 'Gulab Jamun (2)', 5, 30, 'Y');
INSERT INTO MENU_ITEMS VALUES (106, 'Ice Cream Cup', 5, 40, 'Y');
COMMIT;

-- PROCEDURE: PLACE ORDER AND PRINT BILL

CREATE OR REPLACE PROCEDURE PLACE_ORDER (
    P_STUDENT_ID IN NUMBER,
    P_ITEM_ID IN NUMBER,
    P_QUANTITY IN NUMBER
) AS
    V_STUDENT_NAME STUDENTS.NAME%TYPE;
    V_ITEM_NAME MENU_ITEMS.ITEM_NAME%TYPE;
    V_PRICE MENU_ITEMS.PRICE%TYPE;
    V_AVAILABLE MENU_ITEMS.IS_AVAILABLE%TYPE;
    V_ORDER_ID ORDERS.ORDER_ID%TYPE;
    V_TOTAL NUMBER(10,2);
BEGIN
    IF P_QUANTITY IS NULL OR P_QUANTITY <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Quantity must be greater than zero.');
    END IF;

    SELECT NAME INTO V_STUDENT_NAME
    FROM STUDENTS
    WHERE STUDENT_ID = P_STUDENT_ID;

    SELECT ITEM_NAME, PRICE, IS_AVAILABLE
    INTO V_ITEM_NAME, V_PRICE, V_AVAILABLE
    FROM MENU_ITEMS
    WHERE ITEM_ID = P_ITEM_ID;

    IF V_AVAILABLE <> 'Y' THEN
        RAISE_APPLICATION_ERROR(-20002, 'This food item is not available.');
    END IF;

    V_TOTAL := V_PRICE * P_QUANTITY;
    V_ORDER_ID := SEQ_ORDER.NEXTVAL;

    INSERT INTO ORDERS (ORDER_ID, STUDENT_ID, STATUS, TOTAL_AMOUNT)
    VALUES (V_ORDER_ID, P_STUDENT_ID, 'PLACED', V_TOTAL);

    INSERT INTO ORDER_ITEMS (ORDER_ITEM_ID, ORDER_ID, ITEM_ID, QUANTITY, UNIT_PRICE)
    VALUES (SEQ_ORDER_ITEM.NEXTVAL, V_ORDER_ID, P_ITEM_ID, P_QUANTITY, V_PRICE);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('          CANTEENGO - YOUR BILL         ');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Order ID    : ' || V_ORDER_ID);
    DBMS_OUTPUT.PUT_LINE('Student     : ' || V_STUDENT_NAME);
    DBMS_OUTPUT.PUT_LINE('Student ID  : ' || P_STUDENT_ID);
    DBMS_OUTPUT.PUT_LINE('Food Item   : ' || V_ITEM_NAME);
    DBMS_OUTPUT.PUT_LINE('Quantity    : ' || P_QUANTITY);
    DBMS_OUTPUT.PUT_LINE('Price each  : Rs. ' || TO_CHAR(V_PRICE, 'FM9999990.00'));
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('TOTAL BILL  : Rs. ' || TO_CHAR(V_TOTAL, 'FM9999990.00'));
    DBMS_OUTPUT.PUT_LINE('Order Status: PLACED');
    DBMS_OUTPUT.PUT_LINE('Thank you for ordering from CanteenGo!');
    DBMS_OUTPUT.PUT_LINE('========================================');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Student ID or menu item ID does not exist.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PLACE_ORDER;
/

-- ============================================================
-- 6. DISPLAY MENU
-- ============================================================
SELECT ITEM_ID, ITEM_NAME, PRICE
FROM MENU_ITEMS
WHERE IS_AVAILABLE = 'Y'
ORDER BY ITEM_ID;

-- ============================================================
-- 7. USER INPUT AND BILL
-- FreeSQL will ask for these 3 substitution values when running this section.
-- Enter an existing student ID, menu item ID, and quantity.
-- Example: student_id=1002, item_id=10, quantity=2 (bill Rs. 50).
-- ============================================================
BEGIN
    PLACE_ORDER(&student_id, &item_id, &quantity);
END;
/

-- ============================================================
-- 8. BILL AS A QUERY RESULT
-- Shows the most recently created order and its item details.
-- ============================================================
SELECT
    O.ORDER_ID,
    O.STUDENT_ID,
    S.NAME AS STUDENT_NAME,
    M.ITEM_NAME AS FOOD_ITEM,
    I.QUANTITY,
    I.UNIT_PRICE AS PRICE_EACH,
    I.QUANTITY * I.UNIT_PRICE AS ITEM_TOTAL,
    O.TOTAL_AMOUNT AS GRAND_TOTAL,
    O.STATUS
FROM ORDERS O
JOIN STUDENTS S ON S.STUDENT_ID = O.STUDENT_ID
JOIN ORDER_ITEMS I ON I.ORDER_ID = O.ORDER_ID
JOIN MENU_ITEMS M ON M.ITEM_ID = I.ITEM_ID
WHERE O.ORDER_ID = (SELECT MAX(ORDER_ID) FROM ORDERS);


