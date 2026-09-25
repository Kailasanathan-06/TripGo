import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/services/services.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/misc.dart';

class ETicketScreen extends ConsumerStatefulWidget {
  final String pnr;

  const ETicketScreen({super.key, required this.pnr});

  @override
  ConsumerState<ETicketScreen> createState() => _ETicketScreenState();
}

class _ETicketScreenState extends ConsumerState<ETicketScreen> {
  late Future<TicketModel> _future;

  @override
  void initState() {
    super.initState();
    _future = TicketRepository().byPnr(widget.pnr);
  }

  Future<void> _downloadPdf(TicketModel ticket) async {
    try {
      final pdf = await _buildPdf(ticket);
      await Printing.layoutPdf(onLayout: (format) async => pdf);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open PDF: $e')));
    }
  }

  Future<void> _sharePdf(TicketModel ticket) async {
    try {
      final pdf = await _buildPdf(ticket);
      final bytes = pdf;
      await Printing.sharePdf(bytes: bytes, filename: 'tripgo-${ticket.pnr}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  Future<Uint8List> _buildPdf(TicketModel ticket) async {
    final doc = pw.Document();
    final pwFont = pw.Font.helvetica();
    final payload = ticket.payload;
    final seats = (payload['seats'] as List?)?.map((e) => (e as Map)['label']).join(', ') ?? ticket.booking?.seatSummary ?? '';
    final passengers = (payload['passengers'] as List?) ?? const [];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        build: (context) => [
          pw.Container(
            decoration: const pw.BoxDecoration(color: PdfColors.blue700, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TRIPGO E-TICKET', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: pwFont)),
                pw.Text(ticket.status.toUpperCase(), style: pw.TextStyle(fontSize: 12, color: PdfColors.white, font: pwFont)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('PNR: ${ticket.pnr}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: pwFont)),
              pw.Text('Ticket: ${ticket.ticketNumber}', style: pw.TextStyle(fontSize: 12, font: pwFont)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${payload['source'] ?? ''}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: pwFont)),
                  pw.Text('Boarding', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: pwFont)),
                ],
              ),
              pw.Expanded(child: pw.SizedBox()),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                child: pw.Text('Ã¢â€ â€™', style: pw.TextStyle(fontSize: 20, color: PdfColors.blue700, font: pwFont)),
              ),
              pw.Expanded(child: pw.SizedBox()),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('${payload['destination'] ?? ''}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: pwFont)),
                  pw.Text('Destination', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: pwFont)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('${payload['vehicle_name'] ?? ''} Ã‚Â· ${payload['vehicle_number'] ?? ''}', style: pw.TextStyle(fontSize: 13, font: pwFont)),
          pw.Text('Date: ${payload['travel_date'] ?? ''}  |  Seats: $seats', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800, font: pwFont)),
          pw.SizedBox(height: 16),
          pw.Container(
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PASSENGERS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, font: pwFont)),
                pw.SizedBox(height: 6),
                for (final p in passengers)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      '${p['full_name']} Ã‚Â· ${p['age']} yrs (${p['gender']})',
                      style: pw.TextStyle(fontSize: 12, font: pwFont),
                    ),
                  ),
                pw.SizedBox(height: 6),
                pw.Text('Paid: ${formatMoney(ticket.booking?.totalAmount ?? 0)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: pwFont)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Center(child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: ticket.qrData.isEmpty ? ticket.pnr : ticket.qrData, width: 120, height: 120)),
        ],
      ),
    );
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TripGoAppBar(
        title: 'E-Ticket',
        trailing: IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () async {
            try {
              final t = await _future;
              await _sharePdf(t);
            } catch (_) {}
          },
        ),
      ),
      body: FutureBuilder<TicketModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const TripGoLoading(message: 'Fetching your ticketÃ¢â‚¬Â¦');
          }
          if (snapshot.hasError) {
            return TripGoErrorState(message: '${snapshot.error}', onRetry: () => setState(() => _future = TicketRepository().byPnr(widget.pnr)));
          }
          final ticket = snapshot.data!;
          final payload = ticket.payload;
          final booking = ticket.booking;
          final seats = (payload['seats'] as List?)?.map((e) => (e as Map)['label']).join(', ') ?? booking?.seatSummary ?? '';
          final passengers = (payload['passengers'] as List?) ?? const [];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    TripGoCard(
                      padding: EdgeInsets.zero,
                      radius: BorderRadius.circular(AppRadius.xl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                              decoration: const BoxDecoration(gradient: AppColors.gradient),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('TRIPGO E-TICKET', style: AppTypography.smallStyle.copyWith(color: AppColors.white, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                                  TripGoStatusChip.fromState(ticket.status),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _kv('PNR', ticket.pnr),
                                      _kv('Ticket No', ticket.ticketNumber),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _kv('Ticket', booking?.vehicleName.toString() ?? payload['vehicle_name']?.toString() ?? ''),
                                      _kv('Travel date', payload['travel_date']?.toString() ?? ''),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  const Divider(color: AppColors.border),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(payload['source']?.toString() ?? '', style: AppTypography.displayStyle),
                                            Text('Boarding', style: AppTypography.captionStyle),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_rounded, color: AppColors.cyan),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(payload['destination']?.toString() ?? '', style: AppTypography.displayStyle),
                                            Text('Destination', style: AppTypography.captionStyle),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(payload['vehicle_name']?.toString() ?? '', style: AppTypography.smallStyle),
                                      Text('Seats: $seats', style: AppTypography.smallStyle.copyWith(color: AppColors.royalBlue)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TripGoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Passengers', style: AppTypography.headingStyle),
                          const SizedBox(height: AppSpacing.sm),
                          for (final p in passengers)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.royalBlue),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(child: Text('${p['full_name']} Ã‚Â· ${p['age']} yrs (${p['gender']})', style: AppTypography.bodyStyle)),
                                ],
                              ),
                            ),
                          if (booking != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Total paid: ${formatMoney(booking.totalAmount)}', style: AppTypography.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TripGoCard(
                      child: Column(
                        children: [
                          Text('Scan this QR at the boarding gate', style: AppTypography.captionStyle),
                          const SizedBox(height: AppSpacing.md),
                          QrImageView(data: ticket.qrData.isEmpty ? ticket.pnr : ticket.qrData, size: 160),
                          const SizedBox(height: AppSpacing.md),
                          Text(ticket.qrData.isEmpty ? 'QR: ${ticket.pnr}' : 'QR: ${ticket.qrData}', style: AppTypography.captionStyle, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
                  child: Row(
                    children: [
                      Expanded(
                        child: TripGoOutlinedButton(
                          label: 'PDF',
                          icon: Icons.picture_as_pdf_outlined,
                          onPressed: () => _downloadPdf(ticket),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TripGoButton(
                          label: 'Share ticket',
                          icon: Icons.share_rounded,
                          onPressed: () => _sharePdf(ticket),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.captionStyle),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyMedium),
      ],
    );
  }
}