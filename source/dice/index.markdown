---
layout: page
title: "Diceware Password Generator"
date: 2014-06-14 20:59:51 +0200
comments: true
categories: [tools]
---
<div class="jumbotron">
    <h3>Select a language:</h3>
    <p class="lead">
        <select id="lang">
            <option value="English">English</option>
            <option value="Dutch" selected="selected">Dutch</option>
            <option value="Japanese">Japanese</option>
            <option value="Polish">Polish</option>
            <option value="Swedish">Swedish</option>
         </select>
    <h3>Rolls:</h3>
    <p class="lead">
        <input class="form-control" type="text" required="" placeholder="Generated numbers" id="numbers">
    </p>
    <p>
        <a class="btn btn-lg btn-success" role="button" id="prng">Add number</a>
        <a class="btn btn-lg btn-warning" role="button" id="clear">Clear</a>
    </p>
    <h3>Words:</h3>
    <p class="lead">
        <input class="form-control" type="text" required="" placeholder="Generated password" id="output">
    </p>
</div>

<script src="/javascripts/uheprng.js"></script>
<script type="text/javascript">
    $( document ).ready(function() {
        var prng = uheprng(), wordlist = null;
        function loadLang(lang) {
            $.get( "/dice/lib/Diceware"+lang+".txt", function( data ) {
                wordlist = data.split("\n");
                checkRolls();
            });
        }
        function checkRolls() {
            var x = $('#numbers').val();
            if(x.length > 0) {
                var b = x.match(/(.{1,5})/g);
                //$('#output').val(b);
                var d = "";
                b.forEach(function(search){
                    if(search.length == 5) {
                        wordlist.forEach(function(word){
                            if(word.indexOf(search)!=-1) {
                                d += word.replace(/\t/g, ',').replace(/ /g, ',').split(',')[1] + " ";
                            }
                        });
                    }
                });
                d = $.trim(d);
                $('#output').val(d);
            }
        }
        loadLang('Dutch');
        $('#lang').change(function() {
            loadLang($(this).val());
        });
        $('#numbers').bind('keypress', function (event) {
            var regex = new RegExp("^[1-6\b]+$");
            var key = String.fromCharCode(!event.charCode ? event.which : event.charCode);
            if (!regex.test(key)) {
                event.preventDefault();
                return false;
            }
        });
        $('#numbers').keyup(function(){
            checkRolls();
        });
        $( "#prng" ).click(function() {
           $("#numbers").val($('#numbers').val() + (prng(6)+1));
            checkRolls();
        });
        $( "#clear" ).click(function() {
            $("#numbers").val("");
            $("#output").val("");
        });
    });
</script>

### What is this?

This is a diceware password generator. Read about diceware

- [here][5]
- [here][3]
- and [here][4]

### Is this safe?

Probably not, but I've taken some precautions to make sure this is as safe as a browser-based generator can be:

- This generator is implemented in javascript. It runs in your browser, and doesn't send your rolls and/or words to me or anyone else. All the code (except for the PRNG) is on the bottom of the source of this page, and there's not much to see either.
- If you don't use actual dice, but the "Add roll" button instead, you're getting an as-random-as-random-can-possibly-be-in-your-browser number. This page uses a PRNG with exceptionally high entropy. Is it truely random? Of course not; It's still a PSEUDO random number generator after all. You better roll those dice buddy.

### How do I use it?

Easy:

- Roll a real dice, or if you haven't happen to have one on you, use the "Add roll" button instead, which will generate a pseudo random roll for you.
- As soon as you have 5 rolls, a corresponding word will be selected from the diceware word list for you.
- Repeat this as often as you want/need words
- Presto, your new diceware password is ready. Save it to your favorite password manager and off you go.
       
### Credits

- [GRC for their Ultra-High Entropy Pseudo-Random Number Generator][1].
- [Diceware for the multi language word lists][2].
- You, for actually considering a safe password for once, thus making the internet a better place. Good for you!
          
[1]: https://www.grc.com/otg/uheprng.htm
[2]: http://world.std.com/~reinhold/diceware.html#languages
[3]: http://blog.agilebits.com/2011/06/21/toward-better-master-passwords/
[4]: http://blog.agilebits.com/2011/08/10/better-master-passwords-the-geek-edition/
[5]: http://world.std.com/~reinhold/diceware.html