// Java program to compute sum of
// digits in numbers from 1 to n
import java.io.*;
 
class GFG {
     
    // Returns sum of all digits
    // in numbers from 1 to n
    static int countNumbersWith1(int n)
    {
        // initialize result
        int result = 0;
      
        // One by one compute sum of digits
        // in every number from 1 to n
        for (int x=1; x<=n; x++)
            result += has1(x)? 1 : 0;
      
        return result;
    }
     
    // A utility function to compute sum
    // of digits in a given number x
    static boolean has1(int x)
    {
        while (x != 0)
        {
            if (x%10 == 1)
               return true;
            x   = x /10;
        }
        return false;
    }
      
    // Driver Program
    public static void main(String args[])
    {
       int n = 13;
       System.out.println("Count of numbers from 1 to "
                          + " that have 1 as a a digit is "
                          + countNumbersWith1(n)) ;
    }
}
