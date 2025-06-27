import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/journal_model.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }
  
  void _saveJournalEntry() {
    final content = _journalController.text.trim();
    if (content.isEmpty) return;
    
    final journal = Journal(
      date: _selectedDate,
      content: content,
      title: 'Journal Entry for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
      sentiment: _calculateSentiment(content),
    );
    
    // In a real app, we would save this to a provider
    // ref.read(journalProvider.notifier).addJournalEntry(journal);
    
    _journalController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journal entry saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  SentimentType _calculateSentiment(String content) {
    // This is a very simple sentiment analysis
    // In a real app, this would use a more sophisticated algorithm or AI
    final lowerContent = content.toLowerCase();
    
    final positiveWords = [
      'happy', 'glad', 'excited', 'wonderful', 'great', 'good', 'excellent',
      'amazing', 'fantastic', 'joy', 'love', 'success', 'achieve', 'accomplished'
    ];
    
    final negativeWords = [
      'sad', 'upset', 'angry', 'terrible', 'bad', 'awful', 'horrible',
      'disappointed', 'frustrated', 'hate', 'failure', 'fail', 'missed'
    ];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      if (lowerContent.contains(word)) {
        positiveCount++;
      }
    }
    
    for (final word in negativeWords) {
      if (lowerContent.contains(word)) {
        negativeCount++;
      }
    }
    
    if (positiveCount > negativeCount) {
      return SentimentType.positive;
    } else if (negativeCount > positiveCount) {
      return SentimentType.negative;
    } else {
      return SentimentType.neutral;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // In a real app, we would get journal entries from a provider
    // final journalEntries = ref.watch(journalProvider);
    final journalEntries = <Journal>[];
    
    return Scaffold(
      body: Column(
        children: [
          // Date selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Date: '),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // Journal entry for the selected date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journal Entry for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _journalController,
                      decoration: const InputDecoration(
                        hintText: 'Write your thoughts for today...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _saveJournalEntry,
                        child: const Text('Save Entry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Previous journal entries
          Expanded(
            child: journalEntries.isEmpty
                ? const Center(
                    child: Text('No journal entries yet'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: journalEntries.length,
                    itemBuilder: (context, index) {
                      final journalEntry = journalEntries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(journalEntry.date),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Icon(
                                    journalEntry.sentiment == SentimentType.positive
                                        ? Icons.sentiment_satisfied
                                        : journalEntry.sentiment == SentimentType.negative
                                            ? Icons.sentiment_dissatisfied
                                            : Icons.sentiment_neutral,
                                    color: journalEntry.sentiment == SentimentType.positive
                                        ? Colors.green
                                        : journalEntry.sentiment == SentimentType.negative
                                            ? Colors.red
                                            : Colors.grey,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(journalEntry.content),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 