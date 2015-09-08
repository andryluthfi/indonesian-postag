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

        public static final String MATCH_RELATIVE_LOCATION = "([+\\-\\$\\^])(\\d)([!]{0,1})([:=~])([\\w\\?!\\.,\\$\\^]+)";

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
                syntax = syntax.trim();
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
            Pattern patternContext = Pattern.compile(Premises.Premise.MATCH_RELATIVE_LOCATION);
            Matcher matcherContext = patternContext.matcher(scan);
            // System.out.println("solveLocation");
            if (matcherContext.find()) {
                String sign = matcherContext.group(1);
                int relativePosition = Integer.parseInt(matcherContext.group(2));
                String negate = matcherContext.group(3);
                String assign = matcherContext.group(4);
                String compareValue = matcherContext.group(5);

                //String[] subContext = context.split(" ");
                int currentIndex = ambigousCase.getCurrentIndex();
                int contextPosition = sign.equals("+")
                ? (currentIndex + relativePosition)
                : (sign.equals("-") ? 
                    (currentIndex - relativePosition)
                    : (sign.equals("$") ? 
                        ambigousCase.tokens.size()  - relativePosition- 1
                        : 0 + relativePosition));
                
                // System.out.println("sign : " + sign);
                // System.out.println("cur : " + currentIndex);
                // System.out.println("con : " + contextPosition);
                // System.out.println("rel : " + relativePosition);
                


                boolean isValidContext =  (contextPosition >= 0) && (contextPosition < ambigousCase.tokens.size());
                if (isValidContext) {
                    String[] info = ambigousCase.tokens.get(contextPosition).split("\t");
                    int access = assign.equals(":") ? 1 : (assign.equals("=") ? 0 : -1);
                    if(access != -1 && access < info.length) {
                        isTrue = "!".equals(negate) ? !info[access].equalsIgnoreCase(compareValue) : info[access].equalsIgnoreCase(compareValue);
                    } else if(assign.equals("~")) {
                        Pattern patternIndex = Pattern.compile("^([\\$\\^]{0,1})(\\d+)");
                        Matcher matcherIndex = patternIndex.matcher(compareValue);
                        if(matcherIndex.find()) {
                            String signIndex = matcherIndex.group(1);
                            int relativeIndex = Integer.parseInt(matcherIndex.group(2));
                            if(signIndex == null || "".equals(signIndex)) {
                                isTrue = contextPosition == relativeIndex;
                            } else {
                                int index = signIndex.equals("$") ? (ambigousCase.tokens.size() - relativeIndex-1) : (0 + relativePosition);
                                isTrue = contextPosition == index;
                            }
                        }
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
