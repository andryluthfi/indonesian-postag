/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

import java.util.ArrayList;
import java.util.List;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 *
 * @author Andry Luthfi
 */
public class Premises {

    private String ID;
    private List<Premise> list;

    public Premises(String givenID) {
        this.ID = givenID;
        this.list = new ArrayList<Premise>();
    }

    public String getID() {
        return this.ID;
    }

    public void addPremise(String grammar, String output) {
        Premise premise = new Premise(grammar, output, this);
        this.list.add(premise);
    }
    
    public List<Premise> getList() {
        return list;
    }

    
    public class Premise {

        public static final String MATCH_RELATIVE_LOCATION = "([+\\-\\$\\^])(\\d)([:=])([\\w\\?!\\.,]+)";

        public Premises parent;
        public String grammar;
        public String output;

        public Premise(String grammar, String output, Premises parent) {
            this.parent = parent;
            this.grammar = grammar;
            this.output = output;
        }

        public Premise(String grammar, String output) {
            this(grammar, output, null);
        }

        public String trace(Case ambigousCase) {
            String output = "";
            boolean isTrue = false;
            boolean isFirst = true;
            String[] syntaces = this.grammar.split("[aA][nN][dD]");

            for (String syntax : syntaces) {
                if(syntax.matches(Premises.Premise.MATCH_RELATIVE_LOCATION)) {
                    boolean isSolveLocation = this.solveLocation(ambigousCase, syntax);
                    isTrue = isFirst ? isSolveLocation : isTrue && isSolveLocation;
                    isFirst = false;
                }
            }
            
            return isTrue ? this.output : output;
        }

        private boolean solveLocation(Case ambigousCase, String syntax) {
            boolean isTrue = false;
            String scan = syntax.trim().replaceAll(" ", "");
            Pattern neighbor = Pattern.compile(Premises.Premise.MATCH_RELATIVE_LOCATION);
            Matcher matcher = neighbor.matcher(scan);
            // System.out.println("solveLocation");
            if (matcher.find()) {
                String sign = matcher.group(1);
                int relativePosition = Integer.parseInt(matcher.group(2));
                String assign = matcher.group(3);
                String tag = matcher.group(4);

                //String[] subContext = context.split(" ");
                int currentIndex = ambigousCase.getCurrentIndex();
                int contextPosition = sign.equals("+")
                        ? (currentIndex + relativePosition)
                        : (sign.equals("-") ? 
                            (currentIndex - relativePosition)
                            : (sign.equals("$") ? 
                                ambigousCase.tokens.size() - 1
                                : 0));
                
                // System.out.println("sign : " + sign);
                // System.out.println("cur : " + currentIndex);
                // System.out.println("con : " + contextPosition);
                // System.out.println("rel : " + relativePosition);
                
                  

                boolean isValidContext =  (contextPosition >= 0) && (contextPosition < ambigousCase.tokens.size());
                if (isValidContext) {
                    String[] temp = ambigousCase.tokens.get(contextPosition).split("\t");
                    int index = assign.equals(":") ? 1 : (assign.equals("=") ? 0 : -1);
                    if(index != -1 && index < temp.length) {
                        isTrue = temp[index].equalsIgnoreCase(tag);
                    } 
                }

            }

            return isTrue;
        }
    }

    @Override
    public String toString() {
        String output = "";
        for (Premise premise : list) {
            output += String.format("grammar: %s , output %s\n", premise.grammar, premise.output);
        }
        return output;
    }
}
