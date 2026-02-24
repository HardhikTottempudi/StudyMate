import { Ionicons } from '@expo/vector-icons';
import React, { useRef, useState } from 'react';
import {
  Animated,
  Dimensions,
  ImageBackground,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

const { width } = Dimensions.get('window');
const { height } = Dimensions.get('window');

interface Flashcard {
  id: string;
  question: string;
  answer: string;
  category: string;
  difficulty: 'easy' | 'medium' | 'hard';
  mastered: boolean;
}

export default function FlashcardsScreen() {
  const [flashcards, setFlashcards] = useState<Flashcard[]>([
    {
      id: '1',
      question: 'What is the capital of France?',
      answer: 'Paris is the capital and most populous city of France.',
      category: 'Geography',
      difficulty: 'easy',
      mastered: false,
    },
    {
      id: '2',
      question: 'Explain photosynthesis',
      answer: 'Photosynthesis is the process by which plants use sunlight, water, and carbon dioxide to produce oxygen and energy in the form of sugar.',
      category: 'Biology',
      difficulty: 'medium',
      mastered: false,
    },
    {
      id: '3',
      question: 'What is the derivative of x²?',
      answer: 'The derivative of x² is 2x. This follows from the power rule of differentiation.',
      category: 'Mathematics',
      difficulty: 'medium',
      mastered: true,
    },
  ]);



  const [currentCardIndex, setCurrentCardIndex] = useState(0);
  const [showAnswer, setShowAnswer] = useState(false);
  const [studyMode, setStudyMode] = useState(false);
  const [topicInput, setTopicInput] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);
  const flipAnimation = useRef(new Animated.Value(0)).current;

  const categories = ['All', 'Geography', 'Biology', 'Mathematics', 'History', 'Science'];
  const [selectedCategory, setSelectedCategory] = useState('All');

  const filteredCards = flashcards.filter(card =>
    selectedCategory === 'All' || card.category === selectedCategory
  );

  const flipCard = () => {
    Animated.timing(flipAnimation, {
      toValue: showAnswer ? 0 : 1,
      duration: 300,
      useNativeDriver: true,
    }).start();
    setShowAnswer(!showAnswer);
  };

  const nextCard = () => {
    setShowAnswer(false);
    flipAnimation.setValue(0);
    if (currentCardIndex < filteredCards.length - 1) {
      setCurrentCardIndex(currentCardIndex + 1);
    } else {
      setCurrentCardIndex(0);
    }
  };

  const previousCard = () => {
    setShowAnswer(false);
    flipAnimation.setValue(0);
    if (currentCardIndex > 0) {
      setCurrentCardIndex(currentCardIndex - 1);
    } else {
      setCurrentCardIndex(filteredCards.length - 1);
    }
  };

  const markAsMastered = () => {
    const updatedCards = flashcards.map(card =>
      card.id === filteredCards[currentCardIndex].id
        ? { ...card, mastered: !card.mastered }
        : card
    );
    setFlashcards(updatedCards);
  };

  const generateFlashcards = async () => {
    try {
      console.log("Generating flashcards for topic:", topicInput);
      const apiKey = "AIzaSyC0VXu4sK_mh0CtAR9ppGn0afPHZRbZ6jg"; // ⚠️ don’t hardcode in production
      const prompt = `
You are a flashcard creator.
Format:
**Q:** What is photosynthesis?
**A:** Photosynthesis is the process by which green plants convert sunlight into energy.

Generate up to 10 flashcards in that format for the topic: ${topicInput}.
    `;

      // Call Gemini API
      const resp = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
          }),
        }
      );

      const data = await resp.json();
      const rawText =
        data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

      // Parse Q/A lines
      const lines = rawText
        .split("\n")
        .map((l: string) => l.trim())
        .filter(Boolean);

      const cards: { question: string; answer: string }[] = [];
      let q: string | null = null;

      for (const line of lines) {
        if (line.startsWith("**Q:**")) {
          q = line.replace("**Q:**", "").trim();
        } else if (line.startsWith("**A:**") && q) {
          const a = line.replace("**A:**", "").trim();
          cards.push({ question: q, answer: a });
          q = null;
        }
      }

      return cards; // array of {question, answer}
    } catch (err) {
      console.error(err);
      return [];
    }
  }

  const handleGenerate = async () => {
    if (!topicInput.trim()) {
      // optional: add Alert to your imports to show this
      // import { Alert } from 'react-native';
      // Alert.alert('Enter a topic', 'Please type a topic first.');
      return;
    }

    try {
      setIsGenerating(true);

      const qa = await generateFlashcards(); // uses topicInput from state
      if (!qa.length) return;

      const newCards: Flashcard[] = qa.map((c, i) => ({
        id: `${Date.now()}-${i}`,
        question: c.question,
        answer: c.answer,
        category: topicInput.trim(),
        difficulty: 'medium',
        mastered: false,
      }));

      setFlashcards(prev => [...prev, ...newCards]);
      setTopicInput('');
    } finally {
      setIsGenerating(false);
    }
  };


  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'easy': return '#4CAF50';
      case 'medium': return '#FF9800';
      case 'hard': return '#F44336';
      default: return '#9E9E9E';
    }
  };

  const frontInterpolate = flipAnimation.interpolate({
    inputRange: [0, 1],
    outputRange: ['0deg', '180deg'],
  });

  const backInterpolate = flipAnimation.interpolate({
    inputRange: [0, 1],
    outputRange: ['180deg', '360deg'],
  });

  const frontAnimatedStyle = {
    transform: [{ perspective: 1000 }, { rotateY: frontInterpolate }],
  };

  const backAnimatedStyle = {
    transform: [{ perspective: 1000 }, { rotateY: backInterpolate }],
  };

  function CardPreview({
    card,
    onLongPressStudy,
    cardWidth,
  }: {
    card: Flashcard;
    onLongPressStudy?: () => void;
    cardWidth: number;
  }) {
    const flip = React.useRef(new Animated.Value(0)).current;
    const [isFlipped, setIsFlipped] = React.useState(false);

    const frontRotate = flip.interpolate({
      inputRange: [0, 1],
      outputRange: ['0deg', '180deg'],
    });
    const backRotate = flip.interpolate({
      inputRange: [0, 1],
      outputRange: ['180deg', '360deg'],
    });

    const flipNow = () => {
      Animated.timing(flip, {
        toValue: isFlipped ? 0 : 1,
        duration: 300,
        useNativeDriver: true,
      }).start(() => setIsFlipped(!isFlipped));
    };

    return (
      <View style={[miniStyles.wrapper, { width: cardWidth }]}>
        {/* FRONT */}
        <Animated.View
          style={[
            miniStyles.face,
            miniStyles.front,
            { transform: [{ perspective: 1000 }, { rotateY: frontRotate }] },
          ]}
        >
          <View style={miniStyles.headerRow}>
            <Text style={miniStyles.category}>{card.category}</Text>
            {card.mastered && <Ionicons name="checkmark-circle" size={16} color="#4CAF50" />}
          </View>
          <Text style={miniStyles.question} numberOfLines={3}>{card.question}</Text>

          <View style={miniStyles.footerRow}>
            <View
              style={[
                miniStyles.diffDot,
                {
                  backgroundColor:
                    card.difficulty === 'easy'
                      ? '#4CAF50'
                      : card.difficulty === 'medium'
                        ? '#FF9800'
                        : '#F44336',
                },
              ]}
            />
            <Text style={miniStyles.diffText}>{card.difficulty}</Text>
          </View>

          <TouchableOpacity style={miniStyles.tapOverlay} onPress={flipNow} onLongPress={onLongPressStudy} />
        </Animated.View>

        {/* BACK */}
        <Animated.View
          style={[
            miniStyles.face,
            miniStyles.back,
            { transform: [{ perspective: 1000 }, { rotateY: backRotate }] },
          ]}
        >
          <Text style={miniStyles.answer} numberOfLines={6}>
            {card.answer}
          </Text>

          <TouchableOpacity style={miniStyles.tapOverlay} onPress={flipNow} onLongPress={onLongPressStudy} />
        </Animated.View>
      </View>
    );
  }

  const miniStyles = StyleSheet.create({
    wrapper: {
      height: 160,
      marginBottom: 12,
    },
    face: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,

      backgroundColor: '#FFFFFF',
      borderRadius: 12,
      padding: 12,

      shadowColor: '#000',
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.1,
      shadowRadius: 4,
      elevation: 3,

      backfaceVisibility: 'hidden',
    },
    front: { zIndex: 2 },
    back: { zIndex: 1, justifyContent: 'center' },

    headerRow: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: 6,
    },
    category: { fontSize: 12, color: '#667eea', fontWeight: '500' },
    question: { fontSize: 14, color: '#2C3E50', marginBottom: 8, flexShrink: 1 },
    footerRow: { flexDirection: 'row', alignItems: 'center' },
    diffDot: { width: 8, height: 8, borderRadius: 4, marginRight: 6 },
    diffText: { fontSize: 12, color: '#7F8C8D', textTransform: 'capitalize' },

    answer: { fontSize: 13, color: '#34495E', lineHeight: 18, textAlign: 'left' },

    // Full-card invisible press area (tap to flip, long-press to open Study Mode)
    tapOverlay: {
      ...StyleSheet.absoluteFillObject,
      borderRadius: 12,
    },
  });


  if (studyMode && filteredCards.length > 0) {
    const currentCard = filteredCards[currentCardIndex];

    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.studyHeader}>
          <TouchableOpacity onPress={() => setStudyMode(false)}>
            <Ionicons name="arrow-back" size={24} color="#667eea" />
          </TouchableOpacity>
          <Text style={styles.studyTitle}>Study Mode</Text>
          <Text style={styles.cardCounter}>
            {currentCardIndex + 1} / {filteredCards.length}
          </Text>
        </View>

        <View style={styles.cardContainer}>
          <View style={styles.cardWrapper}>
            <Animated.View style={[styles.card, styles.cardFront, frontAnimatedStyle]}>
              <View style={styles.cardHeader}>
                <View style={styles.categoryBadge}>
                  <Text style={styles.categoryText}>{currentCard.category}</Text>
                </View>
                <View style={[styles.difficultyBadge, { backgroundColor: getDifficultyColor(currentCard.difficulty) }]}>
                  <Text style={styles.difficultyText}>{currentCard.difficulty}</Text>
                </View>
              </View>
              <View style={styles.cardContent}>
                <Text style={styles.questionText}>{currentCard.question}</Text>
                <TouchableOpacity style={styles.flipButton} onPress={flipCard}>
                  <Text style={styles.flipButtonText}>Tap to reveal answer</Text>
                  <Ionicons name="refresh-outline" size={20} color="#667eea" />
                </TouchableOpacity>
              </View>
            </Animated.View>

            <Animated.View style={[styles.card, styles.cardBack, backAnimatedStyle]}>
              <View style={styles.cardHeader}>
                <View style={styles.categoryBadge}>
                  <Text style={styles.categoryText}>{currentCard.category}</Text>
                </View>
                {currentCard.mastered && (
                  <View style={styles.masteredBadge}>
                    <Ionicons name="checkmark-circle" size={16} color="#4CAF50" />
                    <Text style={styles.masteredText}>Mastered</Text>
                  </View>
                )}
              </View>
              <View style={styles.cardContent}>
                <Text style={styles.answerText}>{currentCard.answer}</Text>
                <TouchableOpacity style={styles.flipButton} onPress={flipCard}>
                  <Text style={styles.flipButtonText}>Back to question</Text>
                  <Ionicons name="refresh-outline" size={20} color="#667eea" />
                </TouchableOpacity>
              </View>
            </Animated.View>
          </View>
        </View>

        <View style={styles.studyControls}>
          <TouchableOpacity style={styles.controlButton} onPress={previousCard}>
            <Ionicons name="chevron-back" size={24} color="#FFFFFF" />
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.masteryButton, currentCard.mastered && styles.masteryButtonActive]}
            onPress={markAsMastered}
          >
            <Ionicons
              name={currentCard.mastered ? "checkmark-circle" : "checkmark-circle-outline"}
              size={20}
              color="#FFFFFF"
            />
            <Text style={styles.masteryButtonText}>
              {currentCard.mastered ? 'Mastered' : 'Mark as Mastered'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.controlButton} onPress={nextCard}>
            <Ionicons name="chevron-forward" size={24} color="#FFFFFF" />
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>

      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        <ImageBackground source={require('../../assets/images/ai_generated_flashcard.png')} imageStyle={{ borderBottomLeftRadius: 70, borderBottomRightRadius: 70 }} style={styles.aiIcon} resizeMode='cover'>
          {/* Header */}
          {/* <View style={styles.header}>
          <Text style={styles.headerTitle}>AI Flashcards</Text>
          <TouchableOpacity style={styles.statsButton}>
            <Ionicons name="analytics-outline" size={24} color="#667eea" />
          </TouchableOpacity>
        </View> */}

          {/* Stats Overview */}
          {/* <View style={styles.statsSection}>
          <LinearGradient colors={['#667eea', '#764ba2']} style={styles.statsCard}>
            <View style={styles.statItem}>
              <Text style={styles.statNumber}>{flashcards.length}</Text>
              <Text style={styles.statLabel}>Total Cards</Text>
            </View>
            <View style={styles.statItem}>
              <Text style={styles.statNumber}>{flashcards.filter(c => c.mastered).length}</Text>
              <Text style={styles.statLabel}>Mastered</Text>
            </View>
            <View style={styles.statItem}>
              <Text style={styles.statNumber}>{categories.length - 1}</Text>
              <Text style={styles.statLabel}>Categories</Text>
            </View>
          </LinearGradient>
        </View> */}

          {/* AI Generation Section */}
          <View style={styles.generationSection}>
            {/* <ImageBackground source={require('../../assets/images/ai_generated_flashcard.png')}> */}

            <View style={styles.generationCard}>
              <Text style={styles.sectionTitle}>Generate New Cards</Text>
              <ImageBackground source={require('../../assets/images/search_bar.png')} style={{ width: '100%' }} resizeMode='contain' >
                <TextInput
                  style={styles.topicInput}
                  placeholder="Enter topic.."
                  value={topicInput}
                  onChangeText={setTopicInput}
                  multiline={false}
                /></ImageBackground>
              <TouchableOpacity
                style={[styles.generateButton, isGenerating && styles.generateButtonDisabled]}
                onPress={handleGenerate}
                disabled={isGenerating}
              >
                <Text style={styles.generateButtonText}>
                  {isGenerating ? 'Generating...' : 'Generate Cards'}
                </Text>
                <Ionicons name="sparkles" size={20} color="#FFFFFF" />
              </TouchableOpacity>
            </View>
            {/* </ImageBackground> */}
          </View>
        </ImageBackground>

        {/* Category Filter 
        <View style={styles.categorySection}>
          <Text style={styles.sectionTitle}>Categories</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            <View style={styles.categoryContainer}>
              {categories.map((category) => (
                <TouchableOpacity
                  key={category}
                  style={[
                    styles.categoryChip,
                    selectedCategory === category && styles.categoryChipActive
                  ]}
                  onPress={() => setSelectedCategory(category)}
                >
                  <Text style={[
                    styles.categoryChipText,
                    selectedCategory === category && styles.categoryChipTextActive
                  ]}>
                    {category}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </ScrollView>
        </View>*/}

        {/* Flashcards Grid */}
        <View style={styles.cardsSection}>
          <View style={styles.cardsHeader}>
            <Text style={styles.sectionTitle}>Your Flashcards</Text>
            {filteredCards.length > 0 && (
              <TouchableOpacity
                style={styles.studyModeButton}
                onPress={() => {
                  setCurrentCardIndex(0);
                  setShowAnswer(false);
                  setStudyMode(true);
                }}
              >
                <Text style={styles.studyModeText}>Study Mode</Text>
                <Ionicons name="play" size={16} color="#667eea" />
              </TouchableOpacity>
            )}
          </View>

          {filteredCards.length === 0 ? (
            <View style={styles.emptyState}>
              <Ionicons name="library-outline" size={48} color="#BDC3C7" />
              <Text style={styles.emptyStateText}>No flashcards in this category</Text>
              <Text style={styles.emptyStateSubtext}>Generate some cards to get started!</Text>
            </View>
          ) : (
            <View style={styles.cardsGrid}>
              {filteredCards.map((card, idx) => (
                <CardPreview
                  key={card.id}
                  card={card}
                  cardWidth={(width - 52) / 2}
                  onLongPressStudy={() => {
                    setSelectedCategory('All'); // optional: keep as-is if you want
                    setCurrentCardIndex(idx);
                    setShowAnswer(false);
                    setStudyMode(true);
                  }}
                />
              ))}
            </View>

          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    marginTop: 0,
    paddingTop: 0,
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  scrollView: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#2C3E50',
  },
  statsButton: {
    padding: 8,
  },
  statsSection: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  statsCard: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 20,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#FFFFFF',
    opacity: 0.8,
  },
  generationSection: {
    //Imagebackground: require('../../assets/images/ai_generated_flashcard.png'),
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#2C3E50',
    marginBottom: 0,
  },
  generationCard: {
    //backgroundImage: '../../assets/images/ai_generated_flashcard.png',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    height: 180,
    padding: 20,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
    marginTop: '70%',
  },
  aiIcon: {
    //width: 48,
    marginTop: -10,
    height: height * 0.35,
    borderBottomEndRadius: 50,
  },
  topicInput: {
    width: '100%',
    //borderWidth: 1,
    //borderColor: '#E1E8ED',
    borderRadius: 8,
    padding: 12,
    marginLeft: 10,
    marginTop: 10,
    fontSize: 16,
    marginBottom: 16,
    textAlign: 'left',
  },
  generateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#667eea',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
  },
  generateButtonDisabled: {
    opacity: 0.6,
  },
  generateButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    marginRight: 8,
  },
  categorySection: {
    marginTop: '40%',
    marginBottom: 24,
  },
  categoryContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
  },
  categoryChip: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#FFFFFF',
    marginRight: 8,
    borderWidth: 1,
    borderColor: '#E1E8ED',
  },
  categoryChipActive: {
    backgroundColor: '#667eea',
    borderColor: '#667eea',
  },
  categoryChipText: {
    fontSize: 14,
    color: '#2C3E50',
  },
  categoryChipTextActive: {
    color: '#FFFFFF',
    fontWeight: '500',
  },
  cardsSection: {
    paddingTop: '40%',
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  cardsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  studyModeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#667eea',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  studyModeText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '500',
    marginRight: 4,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  emptyStateText: {
    fontSize: 18,
    color: '#7F8C8D',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyStateSubtext: {
    fontSize: 14,
    color: '#BDC3C7',
  },
  cardsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  cardPreview: {
    width: (width - 52) / 2,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 12,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardPreviewHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  cardPreviewCategory: {
    fontSize: 12,
    color: '#667eea',
    fontWeight: '500',
  },
  cardPreviewQuestion: {
    fontSize: 14,
    color: '#2C3E50',
    marginBottom: 12,
    height: 60,
  },
  cardPreviewFooter: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  difficultyIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 6,
  },
  cardPreviewDifficulty: {
    fontSize: 12,
    color: '#7F8C8D',
    textTransform: 'capitalize',
  },

  // Study Mode Styles
  studyHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  studyTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#2C3E50',
  },
  cardCounter: {
    fontSize: 14,
    color: '#667eea',
    fontWeight: '500',
  },
  cardContainer: {
    flex: 1,
    justifyContent: 'center',
    paddingHorizontal: 20,
  },
  cardWrapper: {
    height: 400,
    position: 'relative',
  },
  card: {
    position: 'absolute',
    width: '100%',
    height: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
    backfaceVisibility: 'hidden',
  },
  cardFront: {
    zIndex: 2,
  },
  cardBack: {
    zIndex: 1,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  categoryBadge: {
    backgroundColor: '#F0F4FF',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  categoryText: {
    fontSize: 12,
    color: '#667eea',
    fontWeight: '500',
  },
  difficultyBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  difficultyText: {
    fontSize: 10,
    color: '#FFFFFF',
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  masteredBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#E8F5E8',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  masteredText: {
    fontSize: 10,
    color: '#4CAF50',
    fontWeight: '600',
    marginLeft: 4,
  },
  cardContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  questionText: {
    fontSize: 24,
    fontWeight: '600',
    color: '#2C3E50',
    textAlign: 'center',
    lineHeight: 32,
    marginBottom: 20,
  },
  answerText: {
    fontSize: 18,
    color: '#34495E',
    textAlign: 'center',
    lineHeight: 26,
    marginBottom: 20,
  },
  flipButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F0F4FF',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
  },
  flipButtonText: {
    fontSize: 14,
    color: '#667eea',
    marginRight: 8,
  },
  studyControls: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 20,
  },
  controlButton: {
    backgroundColor: '#667eea',
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: 'center',
    alignItems: 'center',
  },
  masteryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#95A5A6',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 25,
  },
  masteryButtonActive: {
    backgroundColor: '#4CAF50',
  },
  masteryButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 8,
  },
});
