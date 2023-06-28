// ignore_for_file: avoid_print

import 'dart:math';

String result = "Let's have a good day.";

String generateQuote() {
  Future.delayed(const Duration(seconds: 1));
  Random random = Random();
  int randomBuffer = random.nextInt(quotes.length);
  print("Quotes ${quotes.length}"); //TODO: remove after
  result =
      "${quotes.values.elementAt(randomBuffer)} - ${quotes.keys.elementAt(randomBuffer)}";
  return result;
}

var quotes = {
  "Albert Einstein":
      "We cannot solve problems with the kind of thinking we employed when we came up with them.",
  "Mahatma Gandhi":
      "Learn as if you will live forever, live like you will die tomorrow.",
  "Will Rogers": "Don't let yesterday take up too much of today.",
  "John Wooden": "Make each day your masterpiece.",
  "Estée Lauder": "I never dreamed about success. I worked for it.",
  "Jim Rohn": "Happiness is not by chance, but by choice.",
  "Helen Keller": "Keep your face to the sunshine and you cannot see a shadow.",
  "Theodore Roosevelt": "Believe you can and you're halfway there.",
  "George Eliot": "It is never too late to be what you might have been.",
  "Carol Burnett":
      "When you have a dream, you've got to grab it and never let go.",
  "Confucius": "Wherever you go, go with all your heart.",
  "André Gide": "Be faithful to that which exists within yourself.",
  "Meghan Markle": "You are enough just as you are.",
  "T.S. Eliot": "Every moment is a fresh beginning.",
  "Mac Miller": "No matter where life takes me, find me with a smile.",
  "Oprah Winfrey": "Turn your wounds into wisdom.",
  "Maya Angelou": "Try to be a rainbow in someone's cloud.",
  "Oscar Wilde": "Be yourself; everyone else is already taken.",
  "Stephen Chbosky": "We accept the love we think we deserve.",
  "George Addair":
      "Everything you’ve ever wanted is on the other side of fear.",
  "Les Brown":
      "Too many of us are not living our dreams because we are living our fears",
  "Zig Ziglar": "There is no elevator to success. You have to take the stairs.",
  "Paulo Coelho": "Friendship isn’t a big thing—it’s a million little things.",
  "Hasan Minhaj":
      "Your courage to do what's right has to be greater than your fear of getting hurt"
};
