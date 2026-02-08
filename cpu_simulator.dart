import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class CPUSimulator extends StatefulWidget {
  const CPUSimulator({super.key});

  @override
  State<CPUSimulator> createState() => _CPUSimulatorState();
}

class _CPUSimulatorState extends State<CPUSimulator>
    with TickerProviderStateMixin {
  final List<String> registers = List.generate(3, (_) => '');
  final List<TextEditingController> memoryControllers =
      List.generate(10, (index) => TextEditingController());

  // Updated history type
  final List<({String operation, String type})> history = [];

  final ScrollController _scrollController = ScrollController();
  int? selectedMemoryIndex;
  int? selectedRegisterIndex;
  String? selectedFromMemory;
  String? selectedToMemory;
  String? selectedFromRegister;
  String? selectedToRegister;

  // New variables for transfer animations
  late AnimationController _transferAnimationController;
  late Animation<Offset> _transferAnimation;
  bool _isTransferring = false;
  int? _transferValue;
  String? _transferSource;
  String? _transferDestination;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize transfer animation controller
    _transferAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _transferAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _transferAnimationController,
      curve: Curves.easeInOut,
    ));
    _transferAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0), // Start from left
      end: Offset.zero, // End at original position
    ).animate(CurvedAnimation(
      parent: _transferAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    for (var controller in memoryControllers) {
      controller.dispose();
    }
    _animationController.dispose();
    _transferAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performTransferAnimation(int value, String source, String destination) {
    setState(() {
      _isTransferring = true;
      _transferValue = value;
      _transferSource = source;
      _transferDestination = destination;
    });

    _transferAnimationController.forward().then((_) {
      setState(() {
        _isTransferring = false;
        _transferValue = null;
        _transferSource = null;
        _transferDestination = null;
      });
      _transferAnimationController.reset();
    });
  }

  void _addToHistory(String operation, String operationType) {
    setState(() {
      history.add((operation: operation, type: operationType));
    });
    _animateOperation();
  }

  void _animateOperation() {
    _animationController.forward().then((_) {
      Timer(const Duration(milliseconds: 200), () {
        _animationController.reverse();
      });
    });
  }

  void load() {
    if (selectedFromMemory != null && selectedToRegister != null) {
      int memoryIndex = int.parse(selectedFromMemory!.substring(1)) - 1;
      int registerIndex = int.parse(selectedToRegister!.substring(1)) - 1;
      String value = memoryControllers[memoryIndex].text;

      setState(() {
        registers[registerIndex] = value;
        memoryControllers[memoryIndex].clear();
        _addToHistory(
            "Load: ${selectedFromMemory}($value) → ${selectedToRegister}(${registers[registerIndex]})",
            "load");
      });

      _performTransferAnimation(
          int.tryParse(value) ?? 0, selectedFromMemory!, selectedToRegister!);
    }
  }

  void store() {
    if (selectedFromRegister != null && selectedToMemory != null) {
      int registerIndex = int.parse(selectedFromRegister!.substring(1)) - 1;
      int memoryIndex = int.parse(selectedToMemory!.substring(1)) - 1;
      String value = registers[registerIndex];

      setState(() {
        memoryControllers[memoryIndex].text = value;
        _addToHistory(
            "Store: ${selectedFromRegister}($value) → ${selectedToMemory}($value)",
            "store");
      });

      _performTransferAnimation(
          int.tryParse(value) ?? 0, selectedFromRegister!, selectedToMemory!);
    }
  }

  void add() {
    setState(() {
      String r1Value = registers[0];
      String r2Value = registers[1];

      if (r1Value.isNotEmpty && r2Value.isNotEmpty) {
        try {
          int sum = int.parse(r1Value) + int.parse(r2Value);
          registers[2] = sum.toString();
          _addToHistory(
              "Add: R1 + R2 → ($r1Value) + ($r2Value) → R3(${registers[2]})",
              "add");
        } catch (e) {
          // Handle parsing error if needed
        }
      }
    });
  }

  void subtract() {
    setState(() {
      String r1Value = registers[0];
      String r2Value = registers[1];

      if (r1Value.isNotEmpty && r2Value.isNotEmpty) {
        try {
          int diff = int.parse(r1Value) - int.parse(r2Value);
          registers[2] = diff.toString();
          _addToHistory(
              "Sub: R1 - R2 → ($r1Value) - ($r2Value) → R3(${registers[2]})",
              "sub");
        } catch (e) {
          // Handle parsing error if needed
        }
      }
    });
  }

  void reset() {
    setState(() {
      for (int i = 0; i < registers.length; i++) {
        registers[i] = ''; // Change to empty string
      }
      for (var controller in memoryControllers) {
        controller.clear();
      }
      history.clear();
      selectedFromMemory = null;
      selectedToMemory = null;
      selectedFromRegister = null;
      selectedToRegister = null;
      selectedMemoryIndex = null;
      selectedRegisterIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade50,
              Colors.purple.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "✨ Your Virtual CPU Workspace ✨",
                    style: GoogleFonts.poppins(
                      color: Colors.pink.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 24, // Adjust the size as needed
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(delay: 300.ms),
                  IconButton(
                    onPressed: reset,
                    icon: Icon(Icons.refresh_rounded,
                        color: Colors.pink.shade400),
                    tooltip: "Reset All",
                  ).animate().fadeIn(duration: 600.ms).scale(delay: 300.ms),
                ],
              ),
              const SizedBox(height: 16),
              // Main Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return constraints.maxWidth > 1200
                        ? _buildWideLayout()
                        : _buildNarrowLayout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildLeftSection(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildMiddleSection(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildRightSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildLeftSection(),
          const SizedBox(height: 16),
          _buildMiddleSection(),
          const SizedBox(height: 16),
          _buildRightSection(),
        ],
      ),
    );
  }

  Widget _buildLeftSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Registers Card
        ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSectionHeader(Icons.memory_rounded, "CPU"),
                  const SizedBox(height: 16),
                  ...List.generate(
                    3,
                    (index) => _buildRegisterRow(index),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Memory Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(Icons.storage_rounded, "Memory"),
                const SizedBox(height: 16),
                ...List.generate(
                  10,
                  (index) => _buildMemoryRow(index),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiddleSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(Icons.code_rounded, "Instructions"),
                const SizedBox(height: 16),
                _buildInstructionsContent(),
              ],
            ),
          ),
        ).animate().slideX(
              duration: 600.ms,
              begin: 1,
              end: 0,
              curve: Curves.easeOutQuad,
            ),
        const SizedBox(height: 45),
        Center(
          child: Image.asset(
            'assets/logo.png',
            height: 150,
            fit: BoxFit.contain,
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scaleXY(
                begin: 1.0,
                end: 1.15, // Larger scale to make pulsing more visible
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
              )
              .shimmer(
                duration: 1.5.seconds,
                color: Colors.pink.shade200.withOpacity(0.3),
                blendMode: BlendMode.srcATop,
              ),
        ),
      ],
    );
  }

  Widget _buildRightSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader(Icons.history_rounded, "History"),
            const SizedBox(height: 16),
            SizedBox(
              height: 615, // Fixed height for history
              child: _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.pink.shade400),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildRegisterRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              "R${index + 1}:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 35,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selectedRegisterIndex == index
                          ? [Colors.pink.shade100, Colors.purple.shade100]
                          : [Colors.grey.shade50, Colors.grey.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          selectedRegisterIndex = index;
                        });
                      },
                      child: Center(
                        child: Text(
                          registers[
                              index], // Display the register value directly
                          style: TextStyle(
                            fontSize: 16,
                            color: registers[index].isEmpty
                                ? Colors.grey.shade400
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Transfer animation overlay remains the same
                if (_isTransferring && _transferDestination == 'R${index + 1}')
                  Positioned.fill(
                    child: SlideTransition(
                      position: _transferAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.pink.shade200.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _transferValue.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "A${index + 1}:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 31,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selectedMemoryIndex == index
                          ? [Colors.pink.shade100, Colors.purple.shade100]
                          : [Colors.grey.shade50, Colors.grey.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          selectedMemoryIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildMemoryTextField(index),
                      ),
                    ),
                  ),
                ),

                // Transfer animation overlay
                if (_isTransferring && _transferSource == 'A${index + 1}')
                  Positioned.fill(
                    child: SlideTransition(
                      position: _transferAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.pink.shade200.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _transferValue.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInstructionButton("LOAD", Icons.download_rounded, load),
        const SizedBox(height: 8),
        _buildDropdownRow(
          "From:",
          selectedFromMemory,
          List.generate(
            10,
            (index) => DropdownMenuItem(
              value: 'A${index + 1}',
              child: Text('A${index + 1}'),
            ),
          ),
          (value) {
            setState(() {
              selectedFromMemory = value;
              selectedMemoryIndex = int.parse(value!.substring(1)) - 1;
            });
          },
        ),
        const SizedBox(height: 8),
        _buildDropdownRow(
          "To:",
          selectedToRegister,
          List.generate(
            3,
            (index) => DropdownMenuItem(
              value: 'R${index + 1}',
              child: Text('R${index + 1}'),
            ),
          ),
          (value) {
            setState(() {
              selectedToRegister = value;
              selectedRegisterIndex = int.parse(value!.substring(1)) - 1;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildInstructionButton("STORE", Icons.upload_rounded, store),
        const SizedBox(height: 8),
        _buildDropdownRow(
          "From:",
          selectedFromRegister,
          List.generate(
            3,
            (index) => DropdownMenuItem(
              value: 'R${index + 1}',
              child: Text('R${index + 1}'),
            ),
          ),
          (value) {
            setState(() {
              selectedFromRegister = value;
              selectedRegisterIndex = int.parse(value!.substring(1)) - 1;
            });
          },
        ),
        const SizedBox(height: 8),
        _buildDropdownRow(
          "To:",
          selectedToMemory,
          List.generate(
            10,
            (index) => DropdownMenuItem(
              value: 'A${index + 1}',
              child: Text('A${index + 1}'),
            ),
          ),
          (value) {
            setState(() {
              selectedToMemory = value;
              selectedMemoryIndex = int.parse(value!.substring(1)) - 1;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildInstructionButton(
          "Add (R1 + R2 → R3)",
          Icons.add_circle_outline_rounded,
          add,
        ),
        const SizedBox(height: 8),
        _buildInstructionButton(
          "Sub (R1 - R2 → R3)",
          Icons.remove_circle_outline_rounded,
          subtract,
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.builder(
        controller: _scrollController,
        reverse: false,
        padding: const EdgeInsets.all(8),
        itemCount: history.length,
        itemBuilder: (context, index) {
          // Define color gradients for different operation types
          final Map<String, List<Color>> operationColors = {
            "load": [Colors.blue.shade50, Colors.blue.shade100],
            "store": [Colors.green.shade50, Colors.green.shade100],
            "add": [Colors.purple.shade50, Colors.purple.shade100],
            "sub": [Colors.orange.shade50, Colors.orange.shade100],
          };

          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 4.0,
              horizontal: 8.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: operationColors[history[index].type] ??
                      [Colors.white, Colors.grey.shade100],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Text(
                history[index].operation,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slide(begin: const Offset(0.1, 0)),
          );
        },
      ),
    );
  }

  Widget _buildInstructionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink.shade100,
        foregroundColor: Colors.pink.shade700,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }

  Widget _buildMemoryTextField(int index) {
    return TextField(
      controller: memoryControllers[index],
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
      ),
      textAlign: TextAlign.start,
      textAlignVertical: TextAlignVertical.center,
    );
  }

  Widget _buildDropdownRow(
    String label,
    String? value,
    List<DropdownMenuItem<String>> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item.value,
                          child: Text(
                            item.value ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.pink.shade400,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
