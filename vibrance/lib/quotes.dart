// ignore_for_file: avoid_print

import 'dart:math';

String result = "Let's have a good day.";

String generateQuoteV1() {
  //Depreciating this Version because of SetState issues, might bring it back
  Future.delayed(const Duration(seconds: 1));
  Random random = Random();
  int randomBuffer = random.nextInt(quotes.length);
  result =
      "${quotes.values.elementAt(randomBuffer)} - ${quotes.keys.elementAt(randomBuffer)}";
  return result;
}

String generateQuoteV2() {
  Future.delayed(const Duration(seconds: 1));
  int random = int.parse(DateTime.now().toString().substring(8, 10));
  result =
      "${quotes.values.elementAt(random)} - ${quotes.keys.elementAt(random)}";
  return result;
}

var quotes = {
  "Albert Einstein":
      "We cannot solve problems with the kind of thinking we employed when we came up with them.",
  "Mahatma Gandhi":
      "Learn as if you will live forever, live like you will die tomorrow.",
  "Kevin Kruse": "Life is about making an impact, not making an income.",
  "Florence Nightingale":
      "I attribute my success to this: I never gave or took any excuse.",
  "Will Rogers": "Don't let yesterday take up too much of today.",
  "John Wooden": "Make each day your masterpiece.",
  "Estée Lauder": "I never dreamed about success. I worked for it.",
  "Jim Rohn": "Happiness is not by chance, but by choice.",
  "Helen Keller": "Keep your face to the sunshine and you cannot see a shadow.",
  "Theodore Roosevelt": "Believe you can and you're halfway there.",
  "George Eliot": "It is never too late to be what you might have been.",
  "Carol Burnett":
      "When you have a dream, you've got to grab it and never let go.",
  "Buddha": "The mind is everything. What you think you become.",
  "Henry David Thoreau":
      "Go confidently in the direction of your dreams.  Live the life you have imagined.",
  "Confucius": "Wherever you go, go with all your heart.",
  "André Gide": "Be faithful to that which exists within yourself.",
  "Meghan Markle": "You are enough just as you are.",
  "T.S. Eliot": "Every moment is a fresh beginning.",
  "Mac Miller": "No matter where life takes me, find me with a smile.",
  "Oprah Winfrey": "Turn your wounds into wisdom.",
  "Maya Angelou": "Try to be a rainbow in someone's cloud.",
  "Oscar Wilde": "Be yourself; everyone else is already taken.",
  "Stephen Chbosky": "We accept the love we think we deserve.",
  "Arthur Ashe": "Start where you are. Use what you have.  Do what you can.",
  "Lao Tzu": "When I let go of what I am, I become what I might be. ",
  "Dalai Lama":
      "Happiness is not something readymade.  It comes from your own actions.",
  "George Addair":
      "Everything you’ve ever wanted is on the other side of fear.",
  "Steve Jobs":
      "Your time is limited, so don't waste it living someone else's life. Don't be trapped by dogma – which is living with the results of other people's thinking.",
  "Les Brown":
      "Too many of us are not living our dreams because we are living our fears",
  "Zig Ziglar": "There is no elevator to success. You have to take the stairs.",
  "Paulo Coelho": "Friendship isn’t a big thing—it’s a million little things.",
  "Hasan Minhaj":
      "Your courage to do what's right has to be greater than your fear of getting hurt"
};
