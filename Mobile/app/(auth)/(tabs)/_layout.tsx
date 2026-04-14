import { Tabs } from 'expo-router';
import React from 'react';

import { HapticTab } from '@/components/haptic-tab';
import { Fonts, Radius, Semantic, Shadows, Spacing } from '@/constants/theme';
import { IconSymbol } from '@/components/ui/icon-symbol';
import { useRoleTabs } from '@/hooks/use-role-tabs';

export default function TabLayout() {
  const visibleTabs = useRoleTabs();

  const href = (tab: string) => (visibleTabs.includes(tab as any) ? undefined : null);

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: Semantic.primary,
        tabBarInactiveTintColor: Semantic.textMuted,
        headerShown: false,
        tabBarButton: HapticTab,
        tabBarLabelStyle: {
          fontFamily: Fonts.medium,
          fontSize: 11,
        },
        tabBarItemStyle: {
          borderRadius: Radius.lg,
          marginHorizontal: 4,
        },
        tabBarStyle: {
          position: 'absolute',
          left: Spacing.md,
          right: Spacing.md,
          bottom: Spacing.md,
          height: 74,
          paddingTop: 10,
          paddingBottom: 10,
          backgroundColor: 'rgba(24,33,44,0.96)',
          borderWidth: 1,
          borderColor: Semantic.border,
          borderTopWidth: 0,
          borderRadius: Radius.xl,
          ...Shadows.elevated,
        },
      }}>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Dashboard',
          tabBarIcon: ({ color }) => <IconSymbol size={28} name="house.fill" color={color} />,
        }}
      />
      <Tabs.Screen
        name="orders"
        options={{
          title: 'Órdenes',
          href: href('orders'),
          tabBarIcon: ({ color }) => <IconSymbol size={28} name="clipboard.fill" color={color} />,
        }}
      />
      <Tabs.Screen
        name="assignments"
        options={{
          title: 'Asignaciones',
          href: href('assignments'),
          tabBarIcon: ({ color }) => <IconSymbol size={28} name="wrench.fill" color={color} />,
        }}
      />
      <Tabs.Screen
        name="customers"
        options={{
          title: 'Clientes',
          href: href('customers'),
          tabBarIcon: ({ color }) => <IconSymbol size={28} name="person.2.fill" color={color} />,
        }}
      />
      <Tabs.Screen
        name="qc"
        options={{
          title: 'QC',
          href: href('qc'),
          tabBarIcon: ({ color }) => <IconSymbol size={28} name="checkmark.shield.fill" color={color} />,
        }}
      />
      <Tabs.Screen
        name="users"
        options={{
          title: 'Usuarios',
          href: href('users'),
          tabBarIcon: ({ color }) => <IconSymbol size={28} name="person.3.fill" color={color} />,
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Perfil',
          tabBarIcon: ({ color }) => <IconSymbol size={28} name="person.fill" color={color} />,
        }}
      />
    </Tabs>
  );
}
