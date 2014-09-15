
import java.util.Scanner;
import java.util.Arrays;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;
import java.util.HashSet;
import java.util.List;
import java.util.ArrayList;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

public class PrefixTree {

    public NodeMWE root;
    public static boolean isDebugMode = false;

    public static void main(String[] arguments) throws FileNotFoundException, IOException {
        PrefixTree tree = new PrefixTree();
        if (isDebugMode) {
            tree.log();
        }
        //String lexical = list.trace(arguments.length >= 1 ? arguments[0] : "ulang kali");
        //System.out.println(lexical != null ? lexical : "Maaf tidak ditemukan dalam cache");
        File fileInput = new File(arguments.length >= 1 ? arguments[0] : "input.txt");
        isDebugMode = arguments.length >= 2 ? Boolean.parseBoolean(arguments[1]) : false;
        if (fileInput.exists()) {
            BufferedReader reader = new BufferedReader(new FileReader(fileInput));
            String rawText = "";

            for (String x = reader.readLine(); x != null; x = reader.readLine()) {
                rawText += x + "\n";
            }

            rawText = rawText.replaceAll("(?<=[A-Za-z])(?=\\.|\\,|\\!|\\?|\'|\"|\\$)", " ");
            rawText = rawText.replaceAll("(?<=\\.|\\,|\\!|\\?|\'|\"|\\$)(?=[A-Za-z])", " ");

            //regex penentu akhir sebuah konteks
            rawText = rawText.replaceAll("\n", "\n\n");
            rawText = rawText.replaceAll(" ([.?!])", " $1\n");
            //System.out.println(rawText);
            String[] rawTokens = rawText.split("\\s");
            List<String> compiled = new ArrayList<String>();
            Map.Entry<String, String> bestCandidate = null;
            NodeMWE currentNode = tree.root;
            String phrase = "";
            for (int index = 0; index < rawTokens.length; index++) {
                String rawToken = rawTokens[index].trim();
                String debug = "";
                Map.Entry<Boolean, String> response = currentNode.expand(rawToken);
                if (response.getKey().booleanValue()) {
                    currentNode = currentNode.traverse(rawToken);
                    debug = "-Expandable";
                    phrase = phrase.equals("") ? rawToken : phrase + " " + rawToken;
                    if (response.getValue() != null) {
                        bestCandidate = new HashMap.SimpleEntry<String, String>(phrase, response.getValue());
                        debug = "-Expandable | Lexical Found : " + bestCandidate.getKey() + " - " + bestCandidate.getValue();
                    }
                } else {
                    if (bestCandidate != null) {
                        String compile = bestCandidate.getKey() + "\t" + bestCandidate.getValue();
                        debug = "-Restart | Compile : " + compile;
                        compiled.add(compile);
                        compiled.add(rawToken);
                    } else {
                        // mustinya bisa digabung ke bawah ini, secara konsep mereka sama
                        if (!phrase.equals("")) {
                            for (String storedToken : phrase.split(" ")) {
                                compiled.add(storedToken);
                            }
                        }
                        if (tree.root.expand(rawToken).getKey().booleanValue()) {
                            currentNode = tree.root;
                            phrase = "";
                            index--;
                            continue;
                        } else {
                            debug = "-Restart | Compile : " + rawToken;
                            // case : when tree respond with false
                            compiled.add(rawToken);
                        }
                    }
                    phrase = "";
                    bestCandidate = null;
                    currentNode = tree.root;
                }
                if (isDebugMode) {
                    System.out.println(rawToken + " : " + debug);
                }
            }

            for (String instance : compiled) {
                System.out.println(instance);
            }
            if (isDebugMode) {
                System.out.println(tree.trace("rumah sakit"));
            }

        }
    }

    public PrefixTree() throws FileNotFoundException {
        this.root = new NodeMWE();
        this.cache();
    }

    public void cache() throws FileNotFoundException {
        Scanner scanner = new Scanner(new File("./resources/lemma-MWE-root-filtered.tsv"));
        while (scanner.hasNextLine()) {
            String[] columns = scanner.nextLine().split("\t");
            this.root.entry(columns[0].substring(1, columns[0].length() - 1), columns[1]);
        }
    }

    public String trace(String phrase) {
        return this.root.find(phrase);
    }

    public void log() {
        this.root.log();
    }

}

class NodeMWE {

    private Map<String, NodeMWE> branches;
    private String lexical;

    public NodeMWE() {
        this(null);
    }

    public NodeMWE(String lexical) {
        if (lexical != null && !"NULL".equals(lexical)) {
            this.lexical = lexical;
        }
        this.branches = new HashMap<String, NodeMWE>();
    }

    public void entry(String entry, String lexical) {
        String[] entries = entry.trim().split(" ");
        this.entry(entries, lexical);
    }

    public void entry(String[] entries, String lexical) {
        if (entries.length <= 1) {
            if (!this.branches.containsKey(entries[0])) {
                this.branches.put(entries[0], new NodeMWE(lexical));
            } else {
                this.branches.get(entries[0]).lexical = lexical;
            }
        } else {
            String entry = entries[0];
            String[] subEntries = Arrays.copyOfRange(entries, 1, entries.length);

            NodeMWE newbranches = null;
            if (!this.branches.containsKey(entry)) {
                newbranches = new NodeMWE();
                this.branches.put(entry, newbranches);
            }
            NodeMWE subbranches = newbranches == null ? this.branches.get(entry) : newbranches;
            subbranches.entry(subEntries, lexical);
        }
    }

    public String find(String entry) {
        String[] entries = entry.trim().split(" ");
        return this.find(entries);
    }

    public String find(String[] entries) {
        String lexical = null;
        if (entries.length <= 1) {
            if (this.branches.containsKey(entries[0])) {
                lexical = this.branches.get(entries[0]).lexical.toString();
            }
        } else {
            String entry = entries[0];
            String[] subEntries = Arrays.copyOfRange(entries, 1, entries.length);
            if (this.branches.containsKey(entry)) {
                lexical = this.branches.get(entry).find(subEntries);
            }
        }

        return lexical;
    }

    public Map.Entry<Boolean, String> expand(String token) {
        boolean isExpandable = false;
        String lexical = null;
        isExpandable = this.branches.containsKey(token);
        if (isExpandable) {
            NodeMWE descendant = this.branches.get(token);
            if (descendant.lexical != null) {
                lexical = descendant.lexical;
            }
        }
        Map.Entry<Boolean, String> response = new HashMap.SimpleEntry<>(isExpandable, lexical);
        return response;
    }

    public NodeMWE traverse(String token) {
        return this.branches.get(token);
    }

    public void log() {
        this.log(0);
    }

    public void log(int level) {
        for (String node : this.branches.keySet()) {
            int n = level;
            char[] chars = new char[n];
            Arrays.fill(chars, '\t');
            String tabs = new String(chars);
            NodeMWE subbranches = this.branches.get(node);
            System.out.println(tabs + node + " : " + (subbranches.lexical != null ? subbranches.lexical : "[-]"));
            if (subbranches != null) {
                subbranches.log(level + 1);
            }
        }
    }

}
