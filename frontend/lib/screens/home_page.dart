import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rag_using_ollama_fastapi_flutter/services/api_service.dart';
import 'package:rag_using_ollama_fastapi_flutter/services/file_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final ApiService _apiService = ApiService(); // Instantiate ApiService
  final FileService _fileService = FileService(); // Instantiate FileService

  bool _isUploading = false;
  bool _isQuerying = false;
  bool _hasUploadedFile =
      false; // This might need adjustment if multiple files are supported
  String _uploadedFileName = ''; // This might need adjustment
  String _answer = '';
  List<Map<String, String>> _citations = [];
  final List<String> _uploadHistory = []; // Use a list to store multiple names

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Consider fetching initial upload history from the backend on init if needed
  }

  @override
  void dispose() {
    _queryController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPdf() async {
    setState(() {
      _isUploading = true;
      // _hasUploadedFile = false; // Keep this false until success
    });

    try {
      final fileResult = await _fileService.pickPdfFile();

      if (fileResult != null) {
        final uploadResult = await _apiService.uploadPdf(fileResult);

        if (uploadResult.success) {
          setState(() {
            _hasUploadedFile = true;
            _uploadedFileName = uploadResult.fileName ?? 'Unknown File';
            if (!_uploadHistory.contains(_uploadedFileName)) {
              _uploadHistory.add(_uploadedFileName);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully uploaded ${_uploadedFileName}'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload: ${uploadResult.errorMessage}'),
            ),
          );
        }
      } else {
        // User cancelled file picking
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during upload: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _queryPdf() async {
    String query = _queryController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a question')));
      return;
    }

    setState(() {
      _isQuerying = true;
      _answer = '';
      _citations = [];
    });

    try {
      final queryResult = await _apiService.query(query);

      if (queryResult.success) {
        setState(() {
          _answer = queryResult.answer ?? 'No answer found';
          _citations = queryResult.citations ?? [];
        });
      } else {
        setState(() {
          _answer = 'Error: ${queryResult.errorMessage}';
          _citations = []; // Clear citations on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Query failed: ${queryResult.errorMessage}')),
        );
      }
    } catch (e) {
      setState(() {
        _answer = 'Error during query: $e';
        _citations = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during query: $e')));
    } finally {
      setState(() {
        _isQuerying = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    // Ensure the URL is valid before attempting to launch
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RAG PDF Assistant',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(borderRadius: BorderRadius.circular(50)),
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Query', icon: Icon(Icons.search, size: 30)),
            Tab(text: 'Files', icon: Icon(Icons.folder, size: 30)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Query Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Action Card
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surface,
                          colorScheme.surface.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload a PDF',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start by uploading a PDF document to query.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform:
                                    Matrix4.identity()
                                      ..scale(_isUploading ? 0.95 : 1.0),
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isUploading ? null : _pickAndUploadPdf,
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(
                                    _isUploading
                                        ? 'Uploading...'
                                        : 'Upload PDF',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.secondary,
                                    foregroundColor: colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child:
                                    _hasUploadedFile // This only shows the last uploaded file
                                        ? Chip(
                                          avatar: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                          label: Text(
                                            _uploadedFileName,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          backgroundColor:
                                              colorScheme.surfaceVariant,
                                        )
                                        : Text(
                                          'No file uploaded yet',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.5),
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Query Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask a Question',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _queryController,
                          decoration: InputDecoration(
                            hintText: 'Type your question here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _queryController.clear(),
                            ),
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform:
                                Matrix4.identity()
                                  ..scale(_isQuerying ? 0.95 : 1.0),
                            child: ElevatedButton.icon(
                              onPressed: _isQuerying ? null : _queryPdf,
                              icon:
                                  _isQuerying
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                      : const Icon(Icons.search),
                              label: Text(
                                _isQuerying
                                    ? 'Searching...'
                                    : 'Search Documents',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Answer Section
                if (_answer.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Answer:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: _answer.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarkdownBody(
                              data: _answer,
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: colorScheme.onSurface),
                                strong: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                listBullet: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: colorScheme.onSurface),
                              ),
                              selectable: true,
                            ),
                            if (_citations.isNotEmpty) ...[
                              const Divider(height: 32),
                              Text(
                                'Sources:',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _citations.length,
                                itemBuilder: (context, index) {
                                  final citation = _citations[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.description,
                                      color: colorScheme.secondary,
                                    ),
                                    title: Text(
                                      citation['title']!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.open_in_new,
                                        color: colorScheme.secondary,
                                      ),
                                      onPressed:
                                          () => _launchUrl(citation['url']!),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Files Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Uploaded Documents',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform:
                          Matrix4.identity()..scale(_isUploading ? 0.95 : 1.0),
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadPdf,
                        icon: const Icon(Icons.add),
                        label: const Text('Add PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _uploadHistory.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  size: 80,
                                  color: colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No documents uploaded yet',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _pickAndUploadPdf,
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Upload a PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.secondary,
                                    foregroundColor: colorScheme.onSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: _uploadHistory.length,
                            itemBuilder: (context, index) {
                              final fileName = _uploadHistory[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.picture_as_pdf,
                                    color: colorScheme.secondary,
                                  ),
                                  title: Text(
                                    fileName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.open_in_new,
                                      color: colorScheme.secondary,
                                    ),
                                    onPressed:
                                        () => _launchUrl(
                                          '${_apiService.baseUrl}/pdf/$fileName', // Use baseUrl from service
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
