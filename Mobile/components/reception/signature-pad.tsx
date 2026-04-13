import { useCallback, useRef, useState } from 'react';
import {
  GestureResponderEvent,
  PanResponder,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';

interface Point {
  x: number;
  y: number;
}

interface Props {
  onConfirm: (signed: boolean) => void;
  isSubmitting: boolean;
}

export function SignaturePad({ onConfirm, isSubmitting }: Props) {
  const [paths, setPaths] = useState<Point[][]>([]);
  const currentPath = useRef<Point[]>([]);
  const hasSigned = paths.length > 0 && paths.some((p) => p.length > 2);

  const getCoords = useCallback(
    (evt: GestureResponderEvent) => ({
      x: evt.nativeEvent.locationX,
      y: evt.nativeEvent.locationY,
    }),
    [],
  );

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: () => true,
      onPanResponderGrant: (evt) => {
        currentPath.current = [getCoords(evt)];
      },
      onPanResponderMove: (evt) => {
        currentPath.current.push(getCoords(evt));
        // Force a shallow copy for re-render
        setPaths((prev) => [...prev.slice(0, -1), [...currentPath.current]]);
      },
      onPanResponderRelease: () => {
        setPaths((prev) => {
          const cleaned = prev.filter((p) => p !== currentPath.current);
          return [...cleaned, [...currentPath.current]];
        });
        currentPath.current = [];
      },
    }),
  ).current;

  const handleClear = () => {
    setPaths([]);
    currentPath.current = [];
  };

  // Render paths as absolute-positioned dots (lightweight approach that works on both web and native)
  const renderPaths = () =>
    paths.flatMap((path, pi) =>
      path.map((point, i) => (
        <View
          key={`${pi}-${i}`}
          style={[
            styles.dot,
            { left: point.x - 1.5, top: point.y - 1.5 },
          ]}
        />
      )),
    );

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Firma del cliente</Text>
      <Text style={styles.hint}>
        Dibuje la firma en el recuadro de abajo
      </Text>

      <View style={styles.canvasWrapper}>
        <View style={styles.canvas} {...panResponder.panHandlers}>
          {renderPaths()}
          {!hasSigned && (
            <Text style={styles.canvasPlaceholder}>Firme aquí</Text>
          )}
        </View>
      </View>

      <View style={styles.actions}>
        <Pressable style={styles.clearBtn} onPress={handleClear}>
          <Text style={styles.clearBtnText}>Limpiar</Text>
        </Pressable>

        <Pressable
          style={[
            styles.confirmBtn,
            (!hasSigned || isSubmitting) && styles.confirmBtnDisabled,
          ]}
          onPress={() => onConfirm(hasSigned)}
          disabled={!hasSigned || isSubmitting}
        >
          <Text style={styles.confirmBtnText}>
            {isSubmitting ? 'Enviando…' : 'Confirmar Firma'}
          </Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { gap: Spacing.md },
  title: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  hint: { fontSize: TypeScale.label, color: Semantic.secondary },
  canvasWrapper: {
    borderRadius: Radius.lg,
    overflow: 'hidden',
    borderWidth: 2,
    borderColor: Semantic.border,
    borderStyle: 'dashed',
  },
  canvas: {
    height: 200,
    backgroundColor: Semantic.surfaceElevated,
    position: 'relative',
    ...Platform.select({
      web: { cursor: 'crosshair' } as any,
      default: {},
    }),
  },
  canvasPlaceholder: {
    position: 'absolute',
    alignSelf: 'center',
    top: '45%',
    fontSize: TypeScale.body,
    color: Semantic.textMuted,
    fontWeight: '600',
  },
  dot: {
    position: 'absolute',
    width: 3,
    height: 3,
    borderRadius: 1.5,
    backgroundColor: Semantic.onSurface,
  },
  actions: {
    flexDirection: 'row',
    gap: Spacing.md,
  },
  clearBtn: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: Radius.pill,
    alignItems: 'center',
    backgroundColor: Semantic.surface,
    borderWidth: 1,
    borderColor: Semantic.border,
  },
  clearBtnText: {
    fontSize: TypeScale.body,
    fontWeight: '600',
    color: Semantic.secondary,
  },
  confirmBtn: {
    flex: 2,
    paddingVertical: 14,
    borderRadius: Radius.pill,
    alignItems: 'center',
    backgroundColor: Semantic.primary,
    ...Shadows.extruded,
  },
  confirmBtnDisabled: { opacity: 0.5 },
  confirmBtnText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
