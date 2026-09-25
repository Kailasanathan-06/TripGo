import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/fields.dart';
import '../../shared/widgets/misc.dart';

class PassengerScreen extends ConsumerStatefulWidget {
  const PassengerScreen({super.key});

  @override
  ConsumerState<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends ConsumerState<PassengerScreen> {
  final _formKeys = <GlobalKey<FormState>>[];
  final _controllers = <List<TextEditingController>>[];
  final _genders = <String>[];
  final _idType = 'Aadhaar';

  @override
  void initState() {
    super.initState();
    final count = ref.read(searchProvider).passengers;
    final saved = ref.read(passengersProvider);
    for (var i = 0; i < count; i++) {
      _formKeys.add(GlobalKey<FormState>());
      _controllers.add([
        TextEditingController(text: i < saved.length ? saved[i].fullName : ''),
        TextEditingController(text: i < saved.length ? '${saved[i].age}' : ''),
        TextEditingController(text: ''),
        TextEditingController(text: i < saved.length ? saved[i].idNumber : ''),
      ]);
      _genders.add(i < saved.length ? saved[i].gender : 'M');
    }
  }

  @override
  void dispose() {
    for (final list in _controllers) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  bool _validateAll() {
    var ok = true;
    for (final key in _formKeys) {
      if (!(key.currentState?.validate() ?? false)) ok = false;
    }
    return ok;
  }

  void _saveAndContinue() {
    if (!_validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all passenger details correctly.')));
      return;
    }
    final passengers = <PassengerModel>[];
    for (var i = 0; i < _controllers.length; i++) {
      passengers.add(PassengerModel(
        fullName: _controllers[i][0].text.trim(),
        age: int.parse(_controllers[i][1].text.trim()),
        gender: _genders[i],
        mobile: _controllers[i][2].text.trim(),
        idType: _idType,
        idNumber: _controllers[i][3].text.trim(),
      ));
    }
    ref.read(passengersProvider.notifier).state = passengers;
    context.push('/booking/review');
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(bookingFlowProvider);
    return Scaffold(
      appBar: const TripGoAppBar(title: 'Passenger details'),
      body: Column(
        children: [
          if (flow != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${flow.route}\n${flow.travelDateLabel} Â· ${flow.selectedSeats.join(', ')}',
                style: AppTypography.captionStyle,
                maxLines: 2,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              itemCount: _controllers.length,
              itemBuilder: (context, i) => _PassengerForm(
                index: i,
                formKey: _formKeys[i],
                controllers: _controllers[i],
                gender: _genders[i],
                onGender: (g) => setState(() => _genders[i] = g),
                idType: _idType,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
              child: TripGoButton(label: 'Review booking', icon: Icons.arrow_forward_rounded, onPressed: _saveAndContinue),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassengerForm extends StatelessWidget {
  final int index;
  final GlobalKey<FormState> formKey;
  final List<TextEditingController> controllers;
  final String gender;
  final ValueChanged<String> onGender;
  final String idType;

  const _PassengerForm({
    required this.index,
    required this.formKey,
    required this.controllers,
    required this.gender,
    required this.onGender,
    required this.idType,
  });

  @override
  Widget build(BuildContext context) {
    return TripGoCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
                  child: Text('${index + 1}', style: AppTypography.smallStyle.copyWith(color: AppColors.royalBlue, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('Passenger ${index + 1}', style: AppTypography.headingStyle),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TripGoTextField(
              label: 'Full name',
              hint: 'As per government ID',
              controller: controllers[0],
              validator: validateName,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TripGoTextField(
                    label: 'Age',
                    controller: controllers[1],
                    keyboardType: TextInputType.number,
                    validator: validateAge,
                    prefixIcon: Icons.cake_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gender', style: AppTypography.captionStyle),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'M', label: Text('M')),
                          ButtonSegment(value: 'F', label: Text('F')),
                          ButtonSegment(value: 'O', label: Text('O')),
                        ],
                        selected: {gender},
                        onSelectionChanged: (s) => onGender(s.first),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TripGoTextField(
              label: 'Mobile number',
              hint: 'Optional',
              controller: controllers[2],
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                return validateMobile(v);
              },
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            TripGoTextField(
              label: 'ID number ($idType)',
              hint: 'Optional',
              controller: controllers[3],
              keyboardType: TextInputType.text,
              prefixIcon: Icons.badge_outlined,
            ),
          ],
        ),
      ),
    );
  }
}