import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.onSubmitted,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isFocused 
              ? const Color(0xFF273DB7) 
              : Colors.black.withValues(alpha: 0.08),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF273DB7).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        style: const TextStyle(fontSize: 14, color: AppColors.primary),
        onChanged: widget.onChanged,
        onSubmitted: (value) {
          if (widget.onSubmitted != null) {
            widget.onSubmitted!();
          }
        },
        onTap: () {
          setState(() {
            _isFocused = true;
          });
        },
        onEditingComplete: () {
          setState(() {
            _isFocused = false;
          });
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    widget.controller.clear();
                    if (widget.onClear != null) {
                      widget.onClear!();
                    } else if (widget.onChanged != null) {
                      widget.onChanged!('');
                    }
                  },
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}